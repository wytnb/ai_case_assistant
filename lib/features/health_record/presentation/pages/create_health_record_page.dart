import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final TextEditingController _symptomSummaryController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _rawTextController.dispose();
    _symptomSummaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    try {
      await ref
          .read(createHealthRecordControllerProvider.notifier)
          .createHealthRecord(
            rawText: _rawTextController.text,
            symptomSummary: _symptomSummaryController.text,
            notes: _notesController.text,
          );

      if (!mounted) {
        return;
      }

      context.pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> createState = ref.watch(
      createHealthRecordControllerProvider,
    );
    final bool isSubmitting = createState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('新增记录')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _rawTextController,
              enabled: !isSubmitting,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '原始文本',
                hintText: '请输入本次健康记录的文字内容',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入原始文本';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _symptomSummaryController,
              enabled: !isSubmitting,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '症状摘要（选填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              enabled: !isSubmitting,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: Text(isSubmitting ? '保存中...' : '保存记录'),
            ),
            if (createState.hasError) ...<Widget>[
              const SizedBox(height: 12),
              const Text('保存失败，请稍后重试。', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
