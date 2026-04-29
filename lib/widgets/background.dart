import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _drift.stop();
    } else if (state == AppLifecycleState.resumed) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeActive = ModalRoute.of(context)?.isCurrent ?? true;
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppTheme.bgGradient,
              ),
            ),
          ),
        ),
        if (routeActive)
          RepaintBoundary(
            child: Stack(
              children: _animatedBlobs(),
            ),
          )
        else
          ..._staticBlobs(),
        widget.child,
      ],
    );
  }

  List<Widget> _animatedBlobs() => <Widget>[
        Positioned(
          top: -80,
          left: -60,
          child: _Blob(
            size: 260,
            color: AppTheme.primary.withValues(alpha: 0.22),
            drift: _drift,
            phase: 0.0,
            driftDx: 18,
            driftDy: 14,
          ),
        ),
        Positioned(
          top: 120,
          right: -100,
          child: _Blob(
            size: 220,
            color: const Color(0xFFFFB6C1).withValues(alpha: 0.22),
            drift: _drift,
            phase: 0.33,
            driftDx: 14,
            driftDy: 20,
          ),
        ),
        Positioned(
          bottom: -120,
          left: -40,
          child: _Blob(
            size: 280,
            color: const Color(0xFF89B4FF).withValues(alpha: 0.20),
            drift: _drift,
            phase: 0.66,
            driftDx: 22,
            driftDy: 12,
          ),
        ),
      ];

  List<Widget> _staticBlobs() => <Widget>[
        Positioned(
          top: -80,
          left: -60,
          child: _StaticBlob(
            size: 260,
            color: AppTheme.primary.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          top: 120,
          right: -100,
          child: _StaticBlob(
            size: 220,
            color: const Color(0xFFFFB6C1).withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -40,
          child: _StaticBlob(
            size: 280,
            color: const Color(0xFF89B4FF).withValues(alpha: 0.20),
          ),
        ),
      ];
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final Animation<double> drift;
  final double phase;
  final double driftDx;
  final double driftDy;

  const _Blob({
    required this.size,
    required this.color,
    required this.drift,
    this.phase = 0.0,
    this.driftDx = 16,
    this.driftDy = 12,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color,
            color,
            color.withValues(alpha: 0),
          ],
          stops: const <double>[0.0, 0.65, 1.0],
        ),
      ),
    );
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: drift,
        builder: (context, child) {
          final t = (drift.value + phase) * 2 * pi;
          return Transform.translate(
            offset: Offset(driftDx * sin(t), driftDy * cos(t)),
            child: child,
          );
        },
        child: body,
      ),
    );
  }
}

class _StaticBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _StaticBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color, color.withValues(alpha: 0)],
            stops: const <double>[0.0, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}
