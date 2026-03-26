import 'dart:io';

import 'package:ai_case_assistant/app/router/records_navigation.dart';
import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HealthRecordDetailPage extends ConsumerWidget {
  const HealthRecordDetailPage({super.key, required this.healthRecordId});

  final String healthRecordId;

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  void _handleBackNavigation(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(buildRecordsLocation(tab: HealthRecordListTab.records));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HealthEvent?> healthRecordAsync = ref.watch(
      healthRecordDetailProvider(healthRecordId),
    );
    final AsyncValue<List<Attachment>> attachmentsAsync = ref.watch(
      healthRecordAttachmentsProvider(healthRecordId),
    );
    final AsyncValue<Map<String, IntakeSession>> linkedSessionsAsync = ref
        .watch(linkedIntakeSessionsProvider);
    final AsyncValue<void> deleteState = ref.watch(
      deleteHealthRecordControllerProvider,
    );

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, void result) {
        if (didPop) {
          return;
        }
        _handleBackNavigation(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _handleBackNavigation(context)),
          title: const Text('记录详情'),
          actions: <Widget>[
            if (healthRecordAsync.valueOrNull != null)
              IconButton(
                onPressed: deleteState.isLoading
                    ? null
                    : () => _deleteHealthRecord(context, ref),
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除正式记录',
              ),
          ],
        ),
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
                  title: '事件时间',
                  child: Text(_dateFormatter.format(healthRecord.createdAt)),
                ),
                _DetailSection(
                  title: '原始文本',
                  child: Text(
                    _displayTextOrPlaceholder(healthRecord.rawText, '暂无原始文本'),
                  ),
                ),
                _DetailSection(
                  title: '症状摘要',
                  child: Text(
                    _displayTextOrPlaceholder(
                      healthRecord.symptomSummary,
                      '暂无 AI 摘要',
                    ),
                  ),
                ),
                _DetailSection(
                  title: '备注',
                  child: Text(
                    _displayTextOrPlaceholder(healthRecord.notes, '暂无备注'),
                  ),
                ),
                _DetailSection(
                  title: '建议',
                  child: Text(
                    _displayTextOrPlaceholder(
                      healthRecord.actionAdvice,
                      '暂无建议',
                    ),
                  ),
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
                              (Attachment attachment) =>
                                  _AttachmentPreview(attachment: attachment),
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
                linkedSessionsAsync.when(
                  data: (Map<String, IntakeSession> linkedSessions) {
                    final IntakeSession? linkedSession =
                        linkedSessions[healthRecord.id];
                    if (linkedSession == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: FilledButton.tonal(
                        onPressed: () =>
                            context.push('/intake/${linkedSession.id}'),
                        child: const Text('追加补充'),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _InfoState(title: '记录加载失败', message: '请稍后重试。'),
        ),
      ),
    );
  }

  String _displayTextOrPlaceholder(String? value, String placeholder) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return placeholder;
    }

    return normalized;
  }

  Future<void> _deleteHealthRecord(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除正式记录'),
          content: const Text('删除后，这条正式记录将不再出现在列表和报告输入中。'),
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
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(deleteHealthRecordControllerProvider.notifier)
          .deleteHealthRecord(healthRecordId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正式记录已删除。')));
      _handleBackNavigation(context);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试。')));
    }
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment});

  final Attachment attachment;

  Future<void> _showImagePreview(BuildContext context, String heroTag) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close image preview',
      barrierColor: Colors.black87,
      pageBuilder: (_, _, _) => _FullscreenImagePreview(
        filePath: attachment.filePath,
        heroTag: heroTag,
      ),
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(opacity: animation, child: child);
          },
      transitionDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isImageAttachment = attachment.fileType == 'image';
    final String heroTag = 'attachment-${attachment.id}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (isImageAttachment)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showImagePreview(context, heroTag),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Hero(
                      tag: heroTag,
                      child: Image.file(
                        File(attachment.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Text('图片加载失败'),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.attachment_outlined),
                title: Text('当前附件暂不支持预览'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenImagePreview extends StatelessWidget {
  const _FullscreenImagePreview({
    required this.filePath,
    required this.heroTag,
  });

  final String filePath;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Hero(
                      tag: heroTag,
                      child: Image.file(
                        File(filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Text(
                          '图片加载失败',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
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
