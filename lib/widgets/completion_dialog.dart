import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'buttons.dart';

class CompletionDialog extends StatefulWidget {
  final String title;
  final bool reviewMode;
  final VoidCallback onClose;

  const CompletionDialog({
    required this.title,
    required this.reviewMode,
    required this.onClose,
  });

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _checkCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _checkCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(_scaleCtrl.value);
          final scale = 0.86 + 0.14 * t;
          final opacity = _scaleCtrl.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: GlassCard(
                opacity: 0.95,
                radius: 28,
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _AnimatedCheckBadge(animation: _checkCtrl),
                    const SizedBox(height: 18),
                    const Text(
                      '完成啦',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reviewMode
                          ? '今日的复习已完成，继续保持！'
                          : '你完成了 ${widget.title} 的全部单词，进度已保存。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.textSecondary.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: DuolingoButton(
                        label: '回到列表',
                        onTap: widget.onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedCheckBadge extends StatelessWidget {
  final Animation<double> animation;
  const _AnimatedCheckBadge({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        final pop = Curves.easeOutBack.transform(t);
        final ringT = Curves.easeOutCubic.transform(t);
        final popClamped = pop.clamp(0.0, 1.0);
        final iconScale = 0.6 + 0.4 * popClamped;
        final ringScale = 0.7 + 0.9 * ringT;
        final ringOpacity = (1.0 - ringT) * 0.5;
        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: ringOpacity.clamp(0.0, 1.0),
                child: Container(
                  width: 92 * ringScale,
                  height: 92 * ringScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.45),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF34C759),
                      Color(0xFF2BA84A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: iconScale,
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
