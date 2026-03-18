import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HealthRecordListPage extends ConsumerWidget {
  const HealthRecordListPage({super.key});

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _openCreatePage(BuildContext context) async {
    final bool? created = await context.push<bool>('/records/new');
    if (!context.mounted || created != true) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('记录已保存')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HealthEvent>> healthRecordsAsync = ref.watch(
      healthRecordListProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('健康记录列表')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePage(context),
        icon: const Icon(Icons.add),
        label: const Text('新增记录'),
      ),
      body: healthRecordsAsync.when(
        data: (List<HealthEvent> healthRecords) {
          if (healthRecords.isEmpty) {
            return _EmptyState(onCreatePressed: () => _openCreatePage(context));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(healthRecordListProvider);
              await ref.read(healthRecordListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: healthRecords.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final HealthEvent healthRecord = healthRecords[index];
                final String summary = _buildSummary(healthRecord);

                return Card(
                  child: ListTile(
                    title: Text(summary),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        Text(_buildEventTime(healthRecord)),
                        const SizedBox(height: 4),
                        Text('来源：${healthRecord.sourceType}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/records/${healthRecord.id}'),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('记录加载失败，请稍后重试。'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(healthRecordListProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSummary(HealthEvent healthRecord) {
    final String? symptomSummary = healthRecord.symptomSummary?.trim();
    if (symptomSummary != null && symptomSummary.isNotEmpty) {
      return symptomSummary;
    }

    final String fallback = (healthRecord.rawText ?? '').trim();
    if (fallback.isEmpty) {
      return '无摘要';
    }

    if (fallback.length <= 40) {
      return fallback;
    }

    return '${fallback.substring(0, 40)}...';
  }

  String _buildEventTime(HealthEvent healthRecord) {
    return _dateFormatter.format(healthRecord.createdAt);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('还没有健康记录', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '先新增一条文字记录，列表和详情页就能展示真实数据。',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreatePressed,
              child: const Text('去新增记录'),
            ),
          ],
        ),
      ),
    );
  }
}
