import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

// ============================================================
// Scale tap wrapper
// ============================================================

class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.96,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.onTap == null) return;
    _ctrl.forward();
    HapticFeedback.selectionClick();
  }

  void _up(_) {
    if (widget.onTap == null) return;
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ============================================================
// Duolingo-style 3D button
// ============================================================

class DuolingoButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final double radius;
  final double height;
  final double shadowOffset;
  final bool enabled;

  const DuolingoButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = AppTheme.primary,
    this.shadowColor = AppTheme.primaryDark,
    this.textColor = Colors.white,
    this.radius = 16,
    this.height = 54,
    this.shadowOffset = 4,
    this.enabled = true,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _press;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _press = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) {
    if (!widget.enabled || widget.onTap == null) return;
    _ctrl.forward();
    HapticFeedback.mediumImpact();
  }

  void _up(_) {
    if (!widget.enabled || widget.onTap == null) return;
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onTap == null;
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, _) {
            final v = _press.value.clamp(0.0, 1.0);
            final scale = 1.0 - 0.03 * v;
            return SizedBox(
              height: widget.height + widget.shadowOffset,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        height: widget.height + widget.shadowOffset,
                        decoration: BoxDecoration(
                          color: disabled
                              ? AppTheme.textSecondary.withValues(alpha: 0.3)
                              : widget.shadowColor,
                          borderRadius: BorderRadius.circular(widget.radius),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: v * widget.shadowOffset,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        height: widget.height,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: disabled
                              ? AppTheme.textSecondary.withValues(alpha: 0.45)
                              : widget.color,
                          borderRadius: BorderRadius.circular(widget.radius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (widget.icon != null) ...<Widget>[
                              Icon(widget.icon,
                                  color: widget.textColor, size: 18),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: widget.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Circular icon button
// ============================================================

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:
            Icon(icon, size: 18, color: iconColor ?? AppTheme.textPrimary),
      ),
    );
  }
}
