import 'dart:io';

import 'package:ai_case_assistant/core/constants/health_record_limits.dart';
import 'package:ai_case_assistant/features/intake/domain/exceptions/ai_intake_exception.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:ai_case_assistant/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CreateHealthRecordPage extends ConsumerStatefulWidget {
  const CreateHealthRecordPage({super.key});

  @override
  ConsumerState<CreateHealthRecordPage> createState() =>
      _CreateHealthRecordPageState();
}

class _CreateHealthRecordPageState
    extends ConsumerState<CreateHealthRecordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _rawTextController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = <XFile>[];

  @override
  void dispose() {
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await _imagePicker.pickMultiImage();
      if (!mounted || pickedImages.isEmpty) {
        return;
      }

      setState(() {
        _selectedImages = pickedImages;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('选择图片失败，请稍后重试。')));
    }
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    try {
      final bool followUpModeEnabled =
          ref.read(followUpModeEnabledProvider).valueOrNull ?? false;
      final IntakeSubmissionResult result = await ref
          .read(intakeActionControllerProvider.notifier)
          .startIntake(
            rawText: _rawTextController.text,
            followUpModeEnabled: followUpModeEnabled,
            attachmentSourcePaths: _selectedImages
                .map((XFile image) => image.path)
                .toList(),
          );

      if (!mounted) {
        return;
      }

      if (result.isFinal && result.healthEventId != null) {
        context.go('/records/${result.healthEventId}');
      } else {
        context.go('/intake/${result.sessionId}');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_buildErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> createState = ref.watch(
      intakeActionControllerProvider,
    );
    final AsyncValue<bool> followUpModeAsync = ref.watch(
      followUpModeEnabledProvider,
    );
    final bool isSubmitting = createState.isLoading;
    final int selectedImageCount = _selectedImages.length;
    final bool followUpModeEnabled = followUpModeAsync.valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('新增记录')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              '只需输入本次原始描述，可选附上图片。系统会统一走 intake 主链路；若追问模式开启，可能先进入 AI 追问再生成最终记录。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                followUpModeEnabled
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_outlined,
              ),
              title: const Text('当前追问模式'),
              subtitle: Text(followUpModeEnabled ? '已开启' : '已关闭'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rawTextController,
              enabled: !isSubmitting,
              onChanged: (_) => setState(() {}),
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: '原始描述',
                hintText: '例如：昨晚开始喉咙痛，今天早上有点发烧，还拍了化验单照片。',
                border: OutlineInputBorder(),
                helperText: '最多1000字',
              ),
              validator: (String? value) {
                final String normalizedValue = value?.trim() ?? '';
                if (normalizedValue.isEmpty) {
                  return '请输入原始描述';
                }
                if (normalizedValue.length > healthRecordRawTextMaxLength) {
                  return '原始描述不能超过1000字';
                }

                return null;
              },
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_trimmedRawTextLength/$healthRecordRawTextMaxLength',
                style: TextStyle(
                  color: _trimmedRawTextLength > healthRecordRawTextMaxLength
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_selectedImages.isEmpty ? '选择图片' : '重新选择图片'),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedImages.isEmpty
                  ? '当前未选择图片'
                  : '已选择 $selectedImageCount 张图片',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_selectedImages.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final XFile image = _selectedImages[index];
                    return _SelectedImagePreview(filePath: image.path);
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: Text(isSubmitting ? '提交中…' : '开始整理'),
            ),
            if (createState.hasError) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _buildErrorMessage(createState.error),
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildErrorMessage(Object? error) {
    if (error is AiIntakeException) {
      return error.message;
    }

    return '保存失败，请稍后重试。';
  }

  int get _trimmedRawTextLength => _rawTextController.text.trim().length;
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96,
        height: 96,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}
