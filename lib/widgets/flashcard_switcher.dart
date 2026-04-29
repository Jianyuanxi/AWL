import 'package:flutter/material.dart';

class FlashcardSwitcher extends StatefulWidget {
  final Widget child;
  final ValueKey<int> currentKey;
  final int direction;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const FlashcardSwitcher({
    super.key,
    required this.child,
    required this.currentKey,
    required this.direction,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<FlashcardSwitcher> createState() => _FlashcardSwitcherState();
}

class _FlashcardSwitcherState extends State<FlashcardSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Widget? _oldChild;
  ValueKey<int>? _oldKey;
  int _lastDir = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant FlashcardSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentKey != widget.currentKey) {
      _oldChild = oldWidget.child;
      _oldKey = oldWidget.currentKey;
      _lastDir = widget.direction;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 350) {
          widget.onSwipeRight?.call();
        } else if (v < -350) {
          widget.onSwipeLeft?.call();
        }
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final curved = Curves.easeOutCubic.transform(_ctrl.value);
          final w = MediaQuery.of(context).size.width;
          final h = MediaQuery.of(context).size.height;
          final children = <Widget>[];

          if (_oldChild != null && _ctrl.value < 1.0) {
            final sign = _lastDir > 0 ? -1.0 : 1.0;
            final x = sign * 0.75 * curved * w;
            final y = 0.06 * curved * curved * h;
            final angle = sign * 0.18 * curved;
            final scale = 1.0 - 0.08 * curved;

            children.add(
              Opacity(
                opacity: (1.0 - curved).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(x, y),
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: scale,
                      child: IgnorePointer(
                        child: KeyedSubtree(key: _oldKey, child: _oldChild!),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final inSign = _lastDir > 0 ? 1.0 : -1.0;
          final rev = 1.0 - curved;
          final ix = inSign * 0.75 * rev * w;
          final iy = -0.07 * rev * h;
          final iangle = inSign * 0.18 * rev;
          final iscale = 0.94 + 0.06 * curved;

          children.add(
            Opacity(
              opacity: curved.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(ix, iy),
                child: Transform.rotate(
                  angle: iangle,
                  child: Transform.scale(
                    scale: iscale,
                    child: KeyedSubtree(
                      key: widget.currentKey,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          );

          return Stack(alignment: Alignment.center, children: children);
        },
      ),
    );
  }
}
