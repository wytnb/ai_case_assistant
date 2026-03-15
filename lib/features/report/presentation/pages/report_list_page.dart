import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/report/presentation/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReportListPage extends ConsumerWidget {
  const ReportListPage({super.key});

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _generateWeeklyReport(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref
          .read(generateWeeklyReportControllerProvider.notifier)
          .generateWeeklyReport();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('周报已生成并保存。')));
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
    final bool isGenerating = generateState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('报告列表')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isGenerating
                    ? null
                    : () => _generateWeeklyReport(context, ref),
                icon: isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(isGenerating ? '生成中…' : '生成近 7 天周报'),
              ),
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              data: (List<Report> reports) {
                if (reports.isEmpty) {
                  return const _EmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reportListProvider);
                    await ref.read(reportListProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final Report report = reports[index];
                      return Card(
                        child: ListTile(
                          title: Text(report.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 8),
                              Text(
                                report.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              '点击上方按钮即可手动生成近 7 天周报。',
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
