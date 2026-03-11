import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HealthRecordDetailPage extends ConsumerWidget {
  const HealthRecordDetailPage({super.key, required this.healthRecordId});

  final String healthRecordId;

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HealthEvent?> healthRecordAsync = ref.watch(
      healthRecordDetailProvider(healthRecordId),
    );
    final AsyncValue<List<Attachment>> attachmentsAsync = ref.watch(
      healthRecordAttachmentsProvider(healthRecordId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('记录详情')),
      body: healthRecordAsync.when(
        data: (HealthEvent? healthRecord) {
          if (healthRecord == null) {
            return const _InfoState(
              title: '未找到这条记录',
              message: '这条健康记录可能已被删除，或当前 ID 无效。',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _DetailSection(
                title: '发生时间',
                child: Text(_dateFormatter.format(healthRecord.eventTime)),
              ),
              _DetailSection(
                title: '来源类型',
                child: Text(healthRecord.sourceType),
              ),
              _DetailSection(
                title: '原始文本',
                child: Text(healthRecord.rawText ?? '暂无原始文本'),
              ),
              _DetailSection(
                title: '症状摘要',
                child: Text(healthRecord.symptomSummary ?? '暂无症状摘要'),
              ),
              _DetailSection(
                title: '备注',
                child: Text(healthRecord.notes ?? '暂无备注'),
              ),
              _DetailSection(
                title: '附件',
                child: attachmentsAsync.when(
                  data: (List<Attachment> attachments) {
                    if (attachments.isEmpty) {
                      return const Text('暂无附件');
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: attachments
                          .map(
                            (Attachment attachment) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.attachment_outlined),
                              title: Text(attachment.filePath),
                              subtitle: Text(attachment.fileType),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => const Text('附件加载失败，请稍后重试。'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _InfoState(title: '记录加载失败', message: '请稍后重试。'),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
