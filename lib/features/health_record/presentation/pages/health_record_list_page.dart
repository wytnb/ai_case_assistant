import 'package:ai_case_assistant/app/router/records_navigation.dart';
import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HealthRecordListPage extends ConsumerStatefulWidget {
  const HealthRecordListPage({
    super.key,
    this.initialTab = HealthRecordListTab.records,
  });

  final HealthRecordListTab initialTab;

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dayFormatter = DateFormat('yyyy-MM-dd');

  @override
  ConsumerState<HealthRecordListPage> createState() =>
      _HealthRecordListPageState();

  static String formatEventTime(DateTime value) {
    return _dateFormatter.format(value);
  }

  static String formatDay(DateTime value) {
    return _dayFormatter.format(value);
  }
}

class _HealthRecordListPageState extends ConsumerState<HealthRecordListPage> {
  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/');
  }

  void _openCreatePage() {
    context.push('/records/new');
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? current = ref.read(recordEventTimeFilterProvider);
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: current,
      helpText: '按记录时间筛选',
      saveText: '确定',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null) {
      return;
    }

    ref.read(recordEventTimeFilterProvider.notifier).state = DateTimeRange(
      start: DateTime(picked.start.year, picked.start.month, picked.start.day),
      end: DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
        999,
        999,
      ),
    );
  }

  Future<void> _deleteHealthRecord(String healthEventId) async {
    final bool shouldDelete = await _showDeleteDialog(
      title: '删除正式记录',
      message: '删除后，这条正式记录将不再出现在列表和报告输入中。',
    );
    if (!shouldDelete || !mounted) {
      return;
    }

    try {
      await ref
          .read(deleteHealthRecordControllerProvider.notifier)
          .deleteHealthRecord(healthEventId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正式记录已删除。')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试。')));
    }
  }

  Future<void> _deleteDraftSession(String sessionId) async {
    final bool shouldDelete = await _showDeleteDialog(
      title: '删除草稿记录',
      message: '删除后，这条草稿的追问内容和暂存附件都会被清空，且无法恢复。',
    );
    if (!shouldDelete || !mounted) {
      return;
    }

    try {
      await ref
          .read(deleteDraftSessionControllerProvider.notifier)
          .deleteDraftSession(sessionId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('草稿记录已删除。')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试。')));
    }
  }

  Future<bool> _showDeleteDialog({
    required String title,
    required String message,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<HealthEvent>> healthRecordsAsync = ref.watch(
      healthRecordListProvider,
    );
    final AsyncValue<List<IntakeSession>> unfinishedSessionsAsync = ref.watch(
      unfinishedIntakeSessionsProvider,
    );
    final DateTimeRange? dateRange = ref.watch(recordEventTimeFilterProvider);
    final AsyncValue<void> deleteHealthRecordState = ref.watch(
      deleteHealthRecordControllerProvider,
    );
    final AsyncValue<void> deleteDraftSessionState = ref.watch(
      deleteDraftSessionControllerProvider,
    );

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, void result) {
        if (didPop) {
          return;
        }
        _handleBackNavigation();
      },
      child: DefaultTabController(
        key: ValueKey<HealthRecordListTab>(widget.initialTab),
        length: 2,
        initialIndex: widget.initialTab.index,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: _handleBackNavigation),
            title: const Text('健康记录列表'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreatePage,
            icon: const Icon(Icons.add),
            label: const Text('新增记录'),
          ),
          body: switch ((healthRecordsAsync, unfinishedSessionsAsync)) {
            (
              AsyncData<List<HealthEvent>> recordsData,
              AsyncData<List<IntakeSession>> draftsData,
            ) =>
              _LoadedListBody(
                healthRecords: recordsData.value,
                unfinishedSessions: draftsData.value,
                dateRange: dateRange,
                onCreatePressed: _openCreatePage,
                onPickDateRange: _pickDateRange,
                onClearDateRange: () =>
                    ref.read(recordEventTimeFilterProvider.notifier).state =
                        null,
                onDeleteHealthRecord: _deleteHealthRecord,
                onDeleteDraftSession: _deleteDraftSession,
                isDeleteActionEnabled:
                    !deleteHealthRecordState.isLoading &&
                    !deleteDraftSessionState.isLoading,
              ),
            (AsyncError<List<HealthEvent>> _, _) ||
            (_, AsyncError<List<IntakeSession>> _) => Center(
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
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _LoadedListBody extends ConsumerWidget {
  const _LoadedListBody({
    required this.healthRecords,
    required this.unfinishedSessions,
    required this.dateRange,
    required this.onCreatePressed,
    required this.onPickDateRange,
    required this.onClearDateRange,
    required this.onDeleteHealthRecord,
    required this.onDeleteDraftSession,
    required this.isDeleteActionEnabled,
  });

  final List<HealthEvent> healthRecords;
  final List<IntakeSession> unfinishedSessions;
  final DateTimeRange? dateRange;
  final VoidCallback onCreatePressed;
  final Future<void> Function() onPickDateRange;
  final VoidCallback onClearDateRange;
  final Future<void> Function(String healthEventId) onDeleteHealthRecord;
  final Future<void> Function(String sessionId) onDeleteDraftSession;
  final bool isDeleteActionEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (healthRecords.isEmpty && unfinishedSessions.isEmpty) {
      if (dateRange != null) {
        return _FilteredEmptyState(
          dateRange: dateRange!,
          onClearPressed: onClearDateRange,
        );
      }
      return _EmptyState(onCreatePressed: onCreatePressed);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(healthRecordListProvider);
        ref.invalidate(unfinishedIntakeSessionsProvider);
        await Future.wait<void>(<Future<void>>[
          ref.read(healthRecordListProvider.future).then((_) {}),
          ref.read(unfinishedIntakeSessionsProvider.future).then((_) {}),
        ]);
      },
      child: Column(
        children: <Widget>[
          _FilterBar(
            dateRange: dateRange,
            onPickDateRange: onPickDateRange,
            onClearDateRange: onClearDateRange,
          ),
          TabBar(
            tabs: <Widget>[
              const Tab(text: '正式记录'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('草稿记录'),
                    if (unfinishedSessions.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 8),
                      _DraftCountBadge(count: unfinishedSessions.length),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _RecordTab(
                  healthRecords: healthRecords,
                  onDeleteHealthRecord: onDeleteHealthRecord,
                  isDeleteActionEnabled: isDeleteActionEnabled,
                ),
                _DraftTab(
                  sessions: unfinishedSessions,
                  onDeleteDraftSession: onDeleteDraftSession,
                  isDeleteActionEnabled: isDeleteActionEnabled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.dateRange,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  final DateTimeRange? dateRange;
  final Future<void> Function() onPickDateRange;
  final VoidCallback onClearDateRange;

  @override
  Widget build(BuildContext context) {
    final String label = dateRange == null
        ? '全部时间'
        : '${HealthRecordListPage.formatDay(dateRange!.start)} ~ ${HealthRecordListPage.formatDay(dateRange!.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickDateRange,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(label),
            ),
          ),
          if (dateRange != null) ...<Widget>[
            const SizedBox(width: 8),
            TextButton(onPressed: onClearDateRange, child: const Text('清空')),
          ],
        ],
      ),
    );
  }
}

class _RecordTab extends StatelessWidget {
  const _RecordTab({
    required this.healthRecords,
    required this.onDeleteHealthRecord,
    required this.isDeleteActionEnabled,
  });

  final List<HealthEvent> healthRecords;
  final Future<void> Function(String healthEventId) onDeleteHealthRecord;
  final bool isDeleteActionEnabled;

  @override
  Widget build(BuildContext context) {
    if (healthRecords.isEmpty) {
      return const _TabEmptyState(message: '当前筛选条件下没有正式记录。');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: healthRecords.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final HealthEvent healthRecord = healthRecords[index];
        return _RecordPanel(
          title: _displayTitle(healthRecord.rawText),
          timeText: HealthRecordListPage.formatEventTime(
            healthRecord.createdAt,
          ),
          onTap: () => context.push('/records/${healthRecord.id}'),
          onDelete: () => onDeleteHealthRecord(healthRecord.id),
          canDelete: isDeleteActionEnabled,
        );
      },
    );
  }
}

class _DraftTab extends StatelessWidget {
  const _DraftTab({
    required this.sessions,
    required this.onDeleteDraftSession,
    required this.isDeleteActionEnabled,
  });

  final List<IntakeSession> sessions;
  final Future<void> Function(String sessionId) onDeleteDraftSession;
  final bool isDeleteActionEnabled;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _TabEmptyState(message: '当前筛选条件下没有草稿记录。');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final IntakeSession session = sessions[index];
        return _RecordPanel(
          title: _displayTitle(_draftRawText(session)),
          timeText: HealthRecordListPage.formatEventTime(session.eventTime),
          statusText: _buildDraftSubtitle(session),
          trailingText: '继续追问',
          onTap: () => context.push('/intake/${session.id}'),
          onDelete: () => onDeleteDraftSession(session.id),
          canDelete: isDeleteActionEnabled,
        );
      },
    );
  }

  String _buildDraftSubtitle(IntakeSession session) {
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

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({
    required this.title,
    required this.timeText,
    required this.onTap,
    required this.onDelete,
    required this.canDelete,
    this.statusText,
    this.trailingText,
  });

  final String title;
  final String timeText;
  final String? statusText;
  final String? trailingText;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(timeText),
                      if (statusText != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          statusText!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (trailingText != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          trailingText!,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '更多操作',
              enabled: canDelete,
              onSelected: (String value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCountBadge extends StatelessWidget {
  const _DraftCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({
    required this.dateRange,
    required this.onClearPressed,
  });

  final DateTimeRange dateRange;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('当前筛选条件下没有记录', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '${HealthRecordListPage.formatDay(dateRange.start)} ~ ${HealthRecordListPage.formatDay(dateRange.end)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onClearPressed, child: const Text('清空筛选')),
          ],
        ),
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

String _displayTitle(String? value) {
  final String normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return '暂无原始文本';
  }
  return normalized;
}

String _draftRawText(IntakeSession session) {
  final String merged = (session.mergedRawText ?? '').trim();
  if (merged.isNotEmpty) {
    return merged;
  }
  return session.initialRawText.trim();
}
