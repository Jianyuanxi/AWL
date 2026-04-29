import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'buttons.dart';

class GlassBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const GlassBottomNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 0, 56, 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Row(
                children: <Widget>[
                  _navItem(0, CupertinoIcons.book_fill, '学习'),
                  _navItem(1, CupertinoIcons.chart_bar_alt_fill, '统计'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final active = index == i;
    return Expanded(
      child: ScaleTap(
        pressScale: 0.92,
        onTap: () => onChanged(i),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: active ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          builder: (context, v, _) {
            final color = Color.lerp(
              AppTheme.textSecondary,
              AppTheme.primary,
              v,
            )!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.0,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: color,
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
