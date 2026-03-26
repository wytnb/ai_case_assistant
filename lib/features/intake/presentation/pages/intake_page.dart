import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/intake/domain/exceptions/ai_intake_exception.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IntakePage extends ConsumerStatefulWidget {
  const IntakePage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<IntakePage> createState() => _IntakePageState();
}

class _IntakePageState extends ConsumerState<IntakePage> {
  final TextEditingController _replyController = TextEditingController();
  bool _didAutoResume = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final String content = _replyController.text;
    try {
      final IntakeSubmissionResult result = await ref
          .read(intakeActionControllerProvider.notifier)
          .submitUserReply(sessionId: widget.sessionId, content: content);
      _replyController.clear();
      if (!mounted) {
        return;
      }
      if (result.isFinal && result.healthEventId != null) {
        context.go('/records/${result.healthEventId}');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _buildErrorMessage(ref.read(intakeActionControllerProvider).error),
          ),
        ),
      );
    }
  }

  Future<void> _forceFinalize() async {
    try {
      final IntakeSubmissionResult result = await ref
          .read(intakeActionControllerProvider.notifier)
          .forceFinalize(widget.sessionId);
      if (!mounted) {
        return;
      }
      if (result.healthEventId != null) {
        context.go('/records/${result.healthEventId}');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _buildErrorMessage(ref.read(intakeActionControllerProvider).error),
          ),
        ),
      );
    }
  }

  Future<void> _resumeQuestioning() async {
    try {
      final IntakeSubmissionResult result = await ref
          .read(intakeActionControllerProvider.notifier)
          .resumeQuestioning(widget.sessionId);
      if (!mounted) {
        return;
      }
      if (result.isFinal && result.healthEventId != null) {
        context.go('/records/${result.healthEventId}');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('上次追问未完成，请继续重试。')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<IntakeSession?> sessionAsync = ref.watch(
      intakeSessionProvider(widget.sessionId),
    );
    final AsyncValue<List<IntakeMessage>> messagesAsync = ref.watch(
      intakeMessagesProvider(widget.sessionId),
    );
    final AsyncValue<void> actionState = ref.watch(
      intakeActionControllerProvider,
    );
    final AsyncValue<void> deleteState = ref.watch(
      deleteDraftSessionControllerProvider,
    );
    final bool isSubmitting = actionState.isLoading;
    final IntakeSession? currentSession = sessionAsync.valueOrNull;
    final bool canDeleteDraft =
        currentSession != null &&
        currentSession.healthEventId == null &&
        (currentSession.status == 'questioning' ||
            currentSession.status == 'awaiting_user_input');

    return Scaffold(
      appBar: AppBar(
        title: const Text('继续追问'),
        actions: <Widget>[
          if (canDeleteDraft)
            IconButton(
                onPressed: deleteState.isLoading
                    ? null
                    : () => _deleteDraftSession(context),
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除草稿记录',
              ),
        ],
      ),
      body: sessionAsync.when(
        data: (IntakeSession? session) {
          if (session == null) {
            return const _IntakeInfoState(
              title: '未找到追问会话',
              message: '该追问会话可能已被清理或 ID 无效。',
            );
          }

          if (session.status == 'questioning' && !_didAutoResume) {
            _didAutoResume = true;
            Future<void>.microtask(_resumeQuestioning);
          }

          return messagesAsync.when(
            data: (List<IntakeMessage> messages) {
              final bool canReply =
                  !isSubmitting && session.status != 'questioning';
              final bool showForceFinalize =
                  session.status == 'awaiting_user_input';
              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        ...messages.map(
                          (IntakeMessage message) =>
                              _MessageBubble(message: message),
                        ),
                        const SizedBox(height: 8),
                        if (session.status != 'awaiting_user_input')
                          _StatusCard(session: session),
                        if (actionState.hasError) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            _buildErrorMessage(actionState.error),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (session.status == 'questioning')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: <Widget>[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : _resumeQuestioning,
                              child: const Text('继续请求 AI'),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: <Widget>[
                            TextField(
                              controller: _replyController,
                              enabled: canReply,
                              minLines: 3,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: '补充信息',
                                hintText: '继续描述新的症状细节或补充背景。',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                if (showForceFinalize)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : _forceFinalize,
                                      child: const Text('直接生成记录'),
                                    ),
                                  ),
                                if (showForceFinalize)
                                  const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: canReply ? _submitReply : null,
                                    child: Text(
                                      isSubmitting ? '提交中…' : '发送回答',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const _IntakeInfoState(title: '消息加载失败', message: '请稍后重试。'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const _IntakeInfoState(title: '追问会话加载失败', message: '请稍后重试。'),
      ),
    );
  }

  String _buildErrorMessage(Object? error) {
    if (error is AiIntakeException) {
      return error.message;
    }

    return '追问失败，请稍后重试。';
  }

  Future<void> _deleteDraftSession(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除草稿记录'),
          content: const Text('删除后，这条草稿的追问内容和暂存附件都会被清空，且无法恢复。'),
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
          .read(deleteDraftSessionControllerProvider.notifier)
          .deleteDraftSession(widget.sessionId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('草稿记录已删除。')));
      context.go('/records');
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.session});

  final IntakeSession session;

  @override
  Widget build(BuildContext context) {
    String title;
    String body;
    switch (session.status) {
      case 'questioning':
        title = '本轮追问处理中';
        body = '如果上次请求中断，页面会自动重试；你也可以手动继续请求。';
        break;
      case 'awaiting_user_input':
        title = '等待你继续补充';
        body =
            session.latestQuestion == null ||
                session.latestQuestion!.trim().isEmpty
            ? '你可以继续补充更多细节。'
            : session.latestQuestion!;
        break;
      default:
        title = '可继续补充并重新追问';
        body = '当前正式记录已生成，你仍可以继续补充信息后更新原记录。';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final IntakeMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isUser ? '你' : 'AI',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Text(message.content),
          ],
        ),
      ),
    );
  }
}

class _IntakeInfoState extends StatelessWidget {
  const _IntakeInfoState({required this.title, required this.message});

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
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
