import 'dart:convert';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/report/presentation/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportDetailPage extends ConsumerWidget {
  const ReportDetailPage({super.key, required this.reportId});

  final String reportId;

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dayFormatter = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Report?> reportAsync = ref.watch(
      reportDetailProvider(reportId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('报告详情')),
      body: reportAsync.when(
        data: (Report? report) {
          if (report == null) {
            return const _InfoState(
              title: '未找到这份报告',
              message: '报告可能已被删除，或当前链接无效。',
            );
          }

          final List<String> adviceItems = _parseAdvice(report.adviceJson);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _DetailSection(title: '标题', child: Text(report.title)),
              _DetailSection(
                title: '报告类型',
                child: Text(_buildReportTypeLabel(report.reportType)),
              ),
              _DetailSection(
                title: '时间范围',
                child: Text(
                  '${_dayFormatter.format(report.rangeStart)} ~ ${_dayFormatter.format(report.rangeEnd)}',
                ),
              ),
              _DetailSection(title: '摘要', child: Text(report.summary)),
              _DetailSection(
                title: '建议',
                child: adviceItems.isEmpty
                    ? const Text('暂无建议')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: adviceItems
                            .map((String item) => Text('• $item'))
                            .toList(),
                      ),
              ),
              _DetailSection(title: 'Markdown', child: Text(report.markdown)),
              _DetailSection(
                title: '生成时间',
                child: Text(_dateFormatter.format(report.generatedAt)),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _InfoState(title: '报告加载失败', message: '请稍后重试。'),
      ),
    );
  }

  List<String> _parseAdvice(String adviceJson) {
    try {
      final dynamic decoded = jsonDecode(adviceJson);
      if (decoded is! List<dynamic>) {
        return const <String>[];
      }

      return decoded
          .whereType<String>()
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList();
    } catch (_) {
      return const <String>[];
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
