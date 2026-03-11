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

  @override
  void dispose() {
    _rawTextController.dispose();
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
          .createHealthRecord(rawText: _rawTextController.text);

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
      ).showSnackBar(const SnackBar(content: Text('整理失败，请稍后重试。')));
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
            Text(
              '只需输入本次原始描述，系统会先自动整理出症状摘要和备注，再完成保存。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rawTextController,
              enabled: !isSubmitting,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: '原始描述',
                hintText: '例如：昨晚开始喉咙痛，今天早上有点发烧，还伴随轻微咳嗽。',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入原始描述';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: Text(isSubmitting ? '正在整理…' : '保存记录'),
            ),
            if (createState.hasError) ...<Widget>[
              const SizedBox(height: 12),
              const Text('整理失败，请稍后重试。', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
