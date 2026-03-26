import 'dart:ui';

import 'package:ai_case_assistant/core/constants/legal_disclaimer_texts.dart';
import 'package:ai_case_assistant/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isDisclaimerDialogVisible = false;

  void _handleDisclaimerState(AsyncValue<bool> disclaimerAcceptedAsync) {
    if (disclaimerAcceptedAsync.isLoading ||
        disclaimerAcceptedAsync.valueOrNull != false ||
        _isDisclaimerDialogVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisclaimerDialogVisible) {
        return;
      }
      _showFirstUseDisclaimerDialog();
    });
  }

  Future<void> _showFirstUseDisclaimerDialog() async {
    _isDisclaimerDialogVisible = true;
    bool checked = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: false,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return AlertDialog(
                  title: const Text(firstUseDisclaimerTitle),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.62,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(firstUseDisclaimerIntro),
                            const SizedBox(height: 12),
                            const Text(firstUseDisclaimerBody),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: checked,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  checked = value ?? false;
                                });
                              },
                              title: const Text(firstUseConsentCheckboxText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    FilledButton(
                      onPressed: !checked
                          ? null
                          : () async {
                              await ref
                                  .read(
                                    firstUseDisclaimerAcceptedProvider.notifier,
                                  )
                                  .setAccepted(true);
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                      child: const Text('同意并继续'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } finally {
      _isDisclaimerDialogVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> disclaimerAcceptedAsync = ref.watch(
      firstUseDisclaimerAcceptedProvider,
    );
    _handleDisclaimerState(disclaimerAcceptedAsync);

    final AsyncValue<bool> followUpModeAsync = ref.watch(
      followUpModeEnabledProvider,
    );
    final bool followUpModeEnabled = followUpModeAsync.valueOrNull ?? false;
    final bool isLoading = followUpModeAsync.isLoading;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompactHeight = constraints.maxHeight < 640;
            final double primaryButtonSize = isCompactHeight ? 88 : 102;
            final double mainBottomOffset = isCompactHeight ? 112 : 132;
            final double bottomActionPadding = isCompactHeight ? 18 : 30;

            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFFAFDFA)),
                  ),
                ),
                Positioned(
                  top: constraints.maxHeight * 0.06,
                  left: -constraints.maxWidth * 0.34,
                  child: _GlowOrb(
                    size: constraints.maxWidth * 0.9,
                    color: const Color.fromRGBO(16, 185, 129, 0.12),
                  ),
                ),
                Positioned(
                  bottom: constraints.maxHeight * 0.1,
                  right: -constraints.maxWidth * 0.3,
                  child: _GlowOrb(
                    size: constraints.maxWidth * 0.76,
                    color: const Color.fromRGBO(52, 211, 153, 0.14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: isCompactHeight ? 8 : 18),
                      Text(
                        'AI 健康病例助手',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF335A4E),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: mainBottomOffset),
                            child: _PrimaryAddButton(
                              size: primaryButtonSize,
                              onTap: () => context.push('/records/new'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      bottomActionPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FollowUpModeCard(
                            enabled: followUpModeEnabled,
                            isLoading: isLoading,
                            onChanged: (bool value) {
                              ref
                                  .read(followUpModeEnabledProvider.notifier)
                                  .setEnabled(value);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SecondaryActionEntry(
                                icon: Icons.format_list_bulleted_rounded,
                                label: '记录列表',
                                onTap: () => context.push('/records'),
                              ),
                              SizedBox(width: isCompactHeight ? 30 : 40),
                              _SecondaryActionEntry(
                                icon: Icons.description_outlined,
                                label: '健康报告',
                                onTap: () => context.push('/reports'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FollowUpModeCard extends StatelessWidget {
  const _FollowUpModeCard({
    required this.enabled,
    required this.isLoading,
    required this.onChanged,
  });

  final bool enabled;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(15, 118, 110, 0.08),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '追问模式',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF064E3B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '开启后，新建记录会优先进入 AI 追问流程，再生成最终记录。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: enabled, onChanged: isLoading ? null : onChanged),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 0.72],
          ),
        ),
      ),
    );
  }
}

class _PrimaryAddButton extends StatefulWidget {
  const _PrimaryAddButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  State<_PrimaryAddButton> createState() => _PrimaryAddButtonState();
}

class _PrimaryAddButtonState extends State<_PrimaryAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (BuildContext context, Widget? child) {
        final double pulseValue = Curves.easeInOut.transform(
          _pulseController.value,
        );
        final double blurRadius = lerpDouble(
          widget.size * 0.24,
          widget.size * 0.34,
          pulseValue,
        )!;
        final double spreadRadius = lerpDouble(
          0,
          widget.size * 0.12,
          pulseValue,
        )!;
        final double shadowOpacity = lerpDouble(0.22, 0.38, pulseValue)!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapCancel: () => setState(() => _isPressed = false),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: AnimatedScale(
                scale: _isPressed ? 0.92 : 1,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(16, 185, 129, shadowOpacity),
                        blurRadius: blurRadius,
                        spreadRadius: spreadRadius,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: widget.size * 0.44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '新增记录',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF064E3B),
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SecondaryActionEntry extends StatelessWidget {
  const _SecondaryActionEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.66,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: const Color(0xFF4B5563), size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
