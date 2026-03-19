import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HealthRecordListPage extends ConsumerWidget {
  const HealthRecordListPage({super.key});

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  void _openCreatePage(BuildContext context) {
    context.push('/records/new');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HealthEvent>> healthRecordsAsync = ref.watch(
      healthRecordListProvider,
    );
    final AsyncValue<List<IntakeSession>> unfinishedSessionsAsync = ref.watch(
      unfinishedIntakeSessionsProvider,
    );
    final AsyncValue<Map<String, IntakeSession>> linkedSessionsAsync = ref
        .watch(linkedIntakeSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('健康记录列表')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePage(context),
        icon: const Icon(Icons.add),
        label: const Text('新增记录'),
      ),
      body: switch ((
        healthRecordsAsync,
        unfinishedSessionsAsync,
        linkedSessionsAsync,
      )) {
        (
          AsyncData<List<HealthEvent>> recordsData,
          AsyncData<List<IntakeSession>> unfinishedData,
          AsyncData<Map<String, IntakeSession>> linkedData,
        ) =>
          _LoadedListBody(
            healthRecords: recordsData.value,
            unfinishedSessions: unfinishedData.value,
            linkedSessions: linkedData.value,
            onCreatePressed: () => _openCreatePage(context),
          ),
        (_, AsyncError<List<IntakeSession>> _, _) ||
        (AsyncError<List<HealthEvent>> _, _, _) ||
        (_, _, AsyncError<Map<String, IntakeSession>> _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('记录加载失败，请稍后重试。'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(healthRecordListProvider);
                    ref.invalidate(unfinishedIntakeSessionsProvider);
                    ref.invalidate(linkedIntakeSessionsProvider);
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  static String formatEventTime(DateTime value) {
    return _dateFormatter.format(value);
  }
}

class _LoadedListBody extends ConsumerWidget {
  const _LoadedListBody({
    required this.healthRecords,
    required this.unfinishedSessions,
    required this.linkedSessions,
    required this.onCreatePressed,
  });

  final List<HealthEvent> healthRecords;
  final List<IntakeSession> unfinishedSessions;
  final Map<String, IntakeSession> linkedSessions;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (healthRecords.isEmpty && unfinishedSessions.isEmpty) {
      return _EmptyState(onCreatePressed: onCreatePressed);
    }

    final List<Widget> children = <Widget>[];

    if (unfinishedSessions.isNotEmpty) {
      children.add(const _SectionHeader(title: '未完成追问'));
      children.addAll(
        unfinishedSessions.map((IntakeSession session) {
          return Card(
            child: ListTile(
              title: Text(_buildPendingTitle(session)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Text(_buildPendingSubtitle(session)),
                  const SizedBox(height: 4),
                  Text(
                    '更新时间：${HealthRecordListPage.formatEventTime(session.updatedAt)}',
                  ),
                ],
              ),
              trailing: TextButton(
                onPressed: () => context.push('/intake/${session.id}'),
                child: const Text('继续追问'),
              ),
              onTap: () => context.push('/intake/${session.id}'),
            ),
          );
        }),
      );
      children.add(const SizedBox(height: 12));
    }

    if (healthRecords.isNotEmpty) {
      children.add(const _SectionHeader(title: '正式记录'));
      children.addAll(
        healthRecords.map((HealthEvent healthRecord) {
          final IntakeSession? linkedSession = linkedSessions[healthRecord.id];
          return Card(
            child: ListTile(
              title: Text(_buildSummary(healthRecord)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Text(
                    HealthRecordListPage.formatEventTime(
                      healthRecord.createdAt,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('来源：${healthRecord.sourceType}'),
                  if (linkedSession != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            context.push('/intake/${linkedSession.id}'),
                        child: const Text('继续补充'),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/records/${healthRecord.id}'),
            ),
          );
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(healthRecordListProvider);
        ref.invalidate(unfinishedIntakeSessionsProvider);
        ref.invalidate(linkedIntakeSessionsProvider);
        await Future.wait<void>(<Future<void>>[
          ref.read(healthRecordListProvider.future).then((_) {}),
          ref.read(unfinishedIntakeSessionsProvider.future).then((_) {}),
          ref.read(linkedIntakeSessionsProvider.future).then((_) {}),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: children,
      ),
    );
  }

  String _buildSummary(HealthEvent healthRecord) {
    final String symptomSummary = (healthRecord.symptomSummary ?? '').trim();
    if (symptomSummary.isNotEmpty) {
      return symptomSummary;
    }

    return '暂无 AI 摘要';
  }

  String _buildPendingTitle(IntakeSession session) {
    final String summary = (session.draftSymptomSummary ?? '').trim();
    if (summary.isNotEmpty) {
      return summary;
    }

    final String merged = (session.mergedRawText ?? '').trim();
    if (merged.isNotEmpty) {
      return merged.length <= 40 ? merged : '${merged.substring(0, 40)}...';
    }

    return session.initialRawText.length <= 40
        ? session.initialRawText
        : '${session.initialRawText.substring(0, 40)}...';
  }

  String _buildPendingSubtitle(IntakeSession session) {
    if (session.status == 'questioning') {
      return '本轮追问处理中，可继续恢复。';
    }

    final String question = (session.latestQuestion ?? '').trim();
    if (question.isNotEmpty) {
      return question;
    }

    return '等待补充更多信息。';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
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
