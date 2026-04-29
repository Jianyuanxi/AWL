import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class StarToggleButton extends StatefulWidget {
  final bool starred;
  final VoidCallback onTap;
  final double size;

  const StarToggleButton({
    super.key,
    required this.starred,
    required this.onTap,
    this.size = 24,
  });

  @override
  State<StarToggleButton> createState() => _StarToggleButtonState();
}

class _StarToggleButtonState extends State<StarToggleButton>
    with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    final wasStarred = widget.starred;
    widget.onTap();
    _bounce
      ..reset()
      ..forward();
    if (!wasStarred) {
      _burst
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hitSize = widget.size + 16;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                final t = _burst.value;
                if (t == 0) return const SizedBox.shrink();
                final eased = Curves.easeOutCubic.transform(t);
                final ringSize = widget.size * (0.6 + 1.4 * eased);
                final opacity = (1.0 - eased).clamp(0.0, 1.0);
                return IgnorePointer(
                  child: Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.star.withValues(alpha: 0.55 * opacity),
                        width: 2.0 * (1 - 0.5 * eased),
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                final t = _burst.value;
                if (t == 0) return const SizedBox.shrink();
                final eased = Curves.easeOutQuad.transform(t);
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                final reach = widget.size * (0.55 + 0.55 * eased);
                return IgnorePointer(
                  child: SizedBox(
                    width: hitSize,
                    height: hitSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: List<Widget>.generate(6, (i) {
                        final angle = (i / 6) * 2 * pi;
                        final dx = reach * cos(angle);
                        final dy = reach * sin(angle);
                        return Transform.translate(
                          offset: Offset(dx, dy),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppTheme.star.withValues(alpha: opacity),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _bounce,
              builder: (context, _) {
                final t = _bounce.value;
                final punch = sin(t * pi) * 0.45;
                final scale = 1.0 + punch;
                return Transform.scale(
                  scale: scale,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: Icon(
                      widget.starred
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      key: ValueKey<bool>(widget.starred),
                      size: widget.size,
                      color: widget.starred
                          ? AppTheme.star
                          : AppTheme.textSecondary.withValues(alpha: 0.55),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
