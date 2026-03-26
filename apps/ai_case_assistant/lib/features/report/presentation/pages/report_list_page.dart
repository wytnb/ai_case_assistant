import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/report/presentation/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReportListPage extends ConsumerWidget {
  const ReportListPage({super.key});

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dayFormatter = DateFormat('yyyy-MM-dd');

  Future<void> _generateReport(
    BuildContext context,
    WidgetRef ref,
    ReportGenerationType reportType,
  ) async {
    try {
      await ref
          .read(generateWeeklyReportControllerProvider.notifier)
          .generateReport(reportType);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${reportType.displayName}已生成并保存。')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('生成失败，请稍后重试。')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Report>> reportsAsync = ref.watch(reportListProvider);
    final AsyncValue<void> generateState = ref.watch(
      generateWeeklyReportControllerProvider,
    );
    final ReportGenerationType selectedType = ref.watch(
      selectedReportTypeProvider,
    );
    final bool isGenerating = generateState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('报告列表')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<ReportGenerationType>(
                segments: ReportGenerationType.values
                    .map(
                      (ReportGenerationType type) =>
                          ButtonSegment<ReportGenerationType>(
                            value: type,
                            label: Text(type.displayName),
                          ),
                    )
                    .toList(),
                selected: <ReportGenerationType>{selectedType},
                onSelectionChanged: isGenerating
                    ? null
                    : (Set<ReportGenerationType> selection) {
                        ref.read(selectedReportTypeProvider.notifier).state =
                            selection.first;
                      },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isGenerating
                    ? null
                    : () => _generateReport(context, ref, selectedType),
                icon: isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  isGenerating
                      ? '生成中…'
                      : '生成${_buildGenerateButtonLabel(selectedType)}',
                ),
              ),
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              data: (List<Report> reports) {
                final List<Report> filteredReports = reports
                    .where(
                      (Report report) =>
                          report.reportType == selectedType.reportType,
                    )
                    .toList();

                if (filteredReports.isEmpty) {
                  return _EmptyState(reportType: selectedType);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reportListProvider);
                    await ref.read(reportListProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredReports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final Report report = filteredReports[index];
                      final String reportTypeLabel = _buildReportTypeLabel(
                        report.reportType,
                      );
                      return Card(
                        child: ListTile(
                          title: Text(report.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 8),
                              Text('类型：$reportTypeLabel'),
                              const SizedBox(height: 4),
                              Text(
                                '范围：${_dayFormatter.format(report.rangeStart)} ~ ${_dayFormatter.format(report.rangeEnd)}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '生成时间：${_dateFormatter.format(report.generatedAt)}',
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/reports/${report.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _ErrorState(
                onRetry: () => ref.invalidate(reportListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildGenerateButtonLabel(ReportGenerationType reportType) {
    switch (reportType) {
      case ReportGenerationType.week:
        return '近 7 天周报';
      case ReportGenerationType.month:
        return '近 30 天月报';
      case ReportGenerationType.quarter:
        return '近 90 天季报';
    }
  }

  String _buildReportTypeLabel(String reportType) {
    switch (reportType) {
      case 'week':
        return '周报';
      case 'month':
        return '月报';
      case 'quarter':
        return '季报';
      default:
        return reportType;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.reportType});

  final ReportGenerationType reportType;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('还没有报告', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '当前没有${reportType.displayName}，你可以点击上方按钮手动生成。',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('报告加载失败，请稍后重试。'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
