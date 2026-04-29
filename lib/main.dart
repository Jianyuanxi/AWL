import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudyManager.instance.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const WordApp());
}

// ============================================================
// Theme
// ============================================================

class AppTheme {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5048D6);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF2BA84A);
  static const Color danger = Color(0xFFFF3B30);
  static const Color star = Color(0xFFFFB800);

  static const List<Color> bgGradient = <Color>[
    Color(0xFFF8F9FB),
    Color(0xFFEEF1F6),
  ];
}

// ============================================================
// Background with decorative blur circles
// ============================================================

class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  // One shared, slow controller drives all three blobs — far cheaper than
  // three separate AnimationControllers. Each blob picks a phase offset.
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates the animated blobs from the foreground
    // content layer, so the cards above are never repainted on a drift tick.
    // Blobs use cheap RadialGradient fills (no boxShadow blur passes) and
    // animate only `Transform.translate`, which is GPU-cheap.
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
        RepaintBoundary(
          child: Stack(
            children: <Widget>[
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
            ],
          ),
        ),
        widget.child,
      ],
    );
  }
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
            color.withValues(alpha: 0),
          ],
          stops: const <double>[0.0, 1.0],
        ),
      ),
    );
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: drift,
        builder: (context, child) {
          // Smooth sine drift; cheap maths, no rebuilds of `body`.
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

// ============================================================
// Glass card
// ============================================================

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double opacity;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = 22,
    this.opacity = 0.78,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: child,
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // BackdropFilter is GPU-expensive on Android (especially Vivo). When
        // the card is mostly opaque (>=0.7) we skip the blur pass entirely
        // and rely on the white fill — the visual difference is negligible
        // and frame times improve dramatically when many cards are on screen.
        child: opacity >= 0.7
            ? inner
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: inner,
              ),
      ),
    );
  }
}

// ============================================================
// Tap feedback widgets
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

/// Duolingo-style 3D button with snappy press + springy rebound.
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
            final scale = 1.0 - 0.03 * v; // subtle squish
            return SizedBox(
              height: widget.height + widget.shadowOffset,
              child: Stack(
                children: <Widget>[
                  // Bottom shadow plate (the "3D depth")
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
                  // Top face — translates down on press
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
                              Icon(widget.icon, color: widget.textColor, size: 18),
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
        child: Icon(icon, size: 18, color: iconColor ?? AppTheme.textPrimary),
      ),
    );
  }
}

// ============================================================
// Star toggle with burst animation
// ============================================================

/// Animated star button: scale bounce + expanding ring on activate,
/// quick shrink on deactivate. Designed to make favouriting feel tactile.
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
    // Burst only when transitioning to starred (positive feedback).
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
            // Expanding ring burst
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
            // Sparkle dots
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
                              color: AppTheme.star.withValues(alpha: opacity),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
            // Star icon with scale bounce + cross-fade
            AnimatedBuilder(
              animation: _bounce,
              builder: (context, _) {
                final t = _bounce.value;
                // Punch curve: quickly grow then settle (overshoots once).
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

// ============================================================
// Models
// ============================================================

class Word {
  final int id;
  final String english;
  final String phonetic;
  final String chinese;
  final String example;
  int errorCount;

  Word(
    this.id,
    this.english,
    this.phonetic,
    this.chinese,
    this.example, {
    this.errorCount = 0,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      json['id'] as int,
      json['english'] as String,
      json['phonetic'] as String? ?? '',
      json['chinese'] as String? ?? '',
      json['example'] as String? ?? '',
    );
  }
}

class SublistProgress {
  final int currentIndex;
  final int completedCount;
  final bool completed;

  const SublistProgress({
    required this.currentIndex,
    required this.completedCount,
    required this.completed,
  });

  const SublistProgress.empty()
      : currentIndex = 0,
        completedCount = 0,
        completed = false;

  factory SublistProgress.fromJson(Map<String, dynamic> json) {
    return SublistProgress(
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentIndex': currentIndex,
        'completedCount': completedCount,
        'completed': completed,
      };
}

// ============================================================
// State manager
// ============================================================

class StudyManager extends ChangeNotifier {
  StudyManager._();
  static final StudyManager instance = StudyManager._();

  static const String _mistakeCountsKey = 'mistake_counts_v1';
  static const String _mistakeDatesKey = 'mistake_dates_v1';
  static const String _sublistProgressKey = 'sublist_progress_v1';
  static const String _starredKey = 'starred_words_v1';
  static const String _streakKey = 'streak_v1';
  static const String _totalMasteredKey = 'total_mastered_v1';
  static const String _totalAttemptsKey = 'total_attempts_v1';
  static const String _totalCorrectKey = 'total_correct_v1';
  static const String _dailyHistoryKey = 'daily_history_v1';
  static const String _lastActiveTitleKey = 'last_active_title_v1';

  late final SharedPreferences _prefs;
  bool _isReady = false;

  final Map<int, int> _mistakeCounts = <int, int>{};
  final Map<int, String> _mistakeDates = <int, String>{}; // wordId → 'yyyy-MM-dd'
  final Map<String, SublistProgress> _sublistProgress =
      <String, SublistProgress>{};
  final Set<int> _starred = <int>{};
  final Map<String, int> _dailyHistory = <String, int>{}; // 'yyyy-MM-dd' → count

  int _streakDays = 0;
  String? _lastStudyDate; // yyyy-MM-dd
  int _totalMastered = 0;
  int _totalAttempts = 0;
  int _totalCorrect = 0;
  String? _lastActiveTitle;

  Future<void> init() async {
    if (_isReady) return;
    _prefs = await SharedPreferences.getInstance();
    _loadMistakeCounts();
    _loadMistakeDates();
    _loadSublistProgress();
    _loadStarred();
    _loadStats();
    _loadDailyHistory();
    _isReady = true;
  }

  // ----- Mistake counts -----
  void _loadMistakeCounts() {
    final raw = _prefs.getString(_mistakeCountsKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _mistakeCounts
      ..clear()
      ..addEntries(decoded.entries.map((e) => MapEntry(
            int.tryParse(e.key) ?? 0,
            (e.value as num).toInt(),
          )));
    _mistakeCounts.remove(0);
  }

  void _loadMistakeDates() {
    final raw = _prefs.getString(_mistakeDatesKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _mistakeDates
      ..clear()
      ..addEntries(decoded.entries.map((e) => MapEntry(
            int.tryParse(e.key) ?? 0,
            e.value as String,
          )));
    _mistakeDates.remove(0);
  }

  void _loadDailyHistory() {
    final raw = _prefs.getString(_dailyHistoryKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _dailyHistory
      ..clear()
      ..addEntries(decoded.entries.map((e) => MapEntry(
            e.key,
            (e.value as num).toInt(),
          )));
  }

  void _loadSublistProgress() {
    final raw = _prefs.getString(_sublistProgressKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _sublistProgress
      ..clear()
      ..addEntries(decoded.entries.map((e) => MapEntry(
            e.key,
            SublistProgress.fromJson(e.value as Map<String, dynamic>),
          )));
  }

  void _loadStarred() {
    final raw = _prefs.getStringList(_starredKey);
    if (raw == null) return;
    _starred
      ..clear()
      ..addAll(raw.map((s) => int.tryParse(s) ?? 0).where((i) => i != 0));
  }

  void _loadStats() {
    final raw = _prefs.getString(_streakKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _streakDays = (decoded['days'] as num?)?.toInt() ?? 0;
      _lastStudyDate = decoded['lastDate'] as String?;
    }
    _totalMastered = _prefs.getInt(_totalMasteredKey) ?? 0;
    _totalAttempts = _prefs.getInt(_totalAttemptsKey) ?? 0;
    _totalCorrect = _prefs.getInt(_totalCorrectKey) ?? 0;
    _lastActiveTitle = _prefs.getString(_lastActiveTitleKey);
  }

  String? get lastActiveTitle => _lastActiveTitle;

  void _persist() {
    final mistakePayload = <String, int>{
      for (final e in _mistakeCounts.entries) '${e.key}': e.value,
    };
    final mistakeDatesPayload = <String, String>{
      for (final e in _mistakeDates.entries) '${e.key}': e.value,
    };
    final progressPayload = <String, Map<String, dynamic>>{
      for (final e in _sublistProgress.entries) e.key: e.value.toJson(),
    };
    final historyPayload = <String, int>{
      for (final e in _dailyHistory.entries) e.key: e.value,
    };
    _prefs
      ..setString(_mistakeCountsKey, jsonEncode(mistakePayload))
      ..setString(_mistakeDatesKey, jsonEncode(mistakeDatesPayload))
      ..setString(_sublistProgressKey, jsonEncode(progressPayload))
      ..setStringList(
        _starredKey,
        _starred.map((i) => '$i').toList(),
      )
      ..setString(
        _streakKey,
        jsonEncode(<String, dynamic>{
          'days': _streakDays,
          'lastDate': _lastStudyDate,
        }),
      )
      ..setString(_dailyHistoryKey, jsonEncode(historyPayload))
      ..setInt(_totalMasteredKey, _totalMastered)
      ..setInt(_totalAttemptsKey, _totalAttempts)
      ..setInt(_totalCorrectKey, _totalCorrect);
    if (_lastActiveTitle == null) {
      _prefs.remove(_lastActiveTitleKey);
    } else {
      _prefs.setString(_lastActiveTitleKey, _lastActiveTitle!);
    }
  }

  // ----- API: mistakes -----
  void applyMistakeCounts(Iterable<Word> words) {
    for (final w in words) {
      w.errorCount = _mistakeCounts[w.id] ?? 0;
    }
  }

  int mistakeCountFor(Word w) => _mistakeCounts[w.id] ?? 0;

  void recordMistake(Word w) {
    final next = (_mistakeCounts[w.id] ?? 0) + 1;
    _mistakeCounts[w.id] = next;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _mistakeDates[w.id] = today;
    w.errorCount = next;
    _persist();
    notifyListeners();
  }

  void removeMistake(int wordId) {
    if (_mistakeCounts.remove(wordId) != null) {
      _totalMastered++;
    }
    _mistakeDates.remove(wordId);
    _persist();
    notifyListeners();
  }

  List<Word> forgottenWords(Iterable<Word> all) {
    final list = all
        .where((w) => (_mistakeCounts[w.id] ?? 0) > 0)
        .map((w) {
      w.errorCount = _mistakeCounts[w.id] ?? 0;
      return w;
    }).toList();
    list.sort((a, b) {
      final c = b.errorCount.compareTo(a.errorCount);
      return c != 0 ? c : a.english.compareTo(b.english);
    });
    return list;
  }

  // ----- SRS spaced repetition -----
  static const List<int> _srsIntervals = <int>[1, 3, 7];

  int srsDueCount(Iterable<Word> all) {
    return srsDueWords(all).length;
  }

  List<Word> srsDueWords(Iterable<Word> all) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final due = <Word>[];
    for (final w in all) {
      final dateStr = _mistakeDates[w.id];
      if (dateStr == null) continue;
      final parts = dateStr.split('-');
      if (parts.length != 3) continue;
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final diff = todayDate.difference(d).inDays;
      if (_srsIntervals.contains(diff)) {
        w.errorCount = _mistakeCounts[w.id] ?? 0;
        due.add(w);
      }
    }
    due.sort((a, b) {
      final c = b.errorCount.compareTo(a.errorCount);
      return c != 0 ? c : a.english.compareTo(b.english);
    });
    return due;
  }

  // ----- daily history for charts -----
  Map<String, int> get dailyHistory => Map<String, int>.from(_dailyHistory);

  // ----- API: progress -----
  SublistProgress progressFor(String title) =>
      _sublistProgress[title] ?? const SublistProgress.empty();

  int startOrResumeSublist(String title, int total) {
    if (total <= 0) return 0;
    final p = progressFor(title);
    if (p.completed) {
      _sublistProgress[title] = const SublistProgress.empty();
      _persist();
      notifyListeners();
      return 0;
    }
    return p.currentIndex.clamp(0, total - 1);
  }

  void saveCurrentPosition(
    String title, {
    required int currentIndex,
    required int totalWords,
  }) {
    if (totalWords <= 0) return;
    final safeIndex = currentIndex.clamp(0, totalWords - 1);
    final prev = progressFor(title);
    final completed = max(
      prev.completed ? 0 : prev.completedCount,
      safeIndex,
    ).clamp(0, totalWords);
    _sublistProgress[title] = SublistProgress(
      currentIndex: safeIndex,
      completedCount: completed,
      completed: false,
    );
    _lastActiveTitle = title;
    _persist();
    notifyListeners();
  }

  void markSublistCompleted(String title, int total) {
    _sublistProgress[title] = SublistProgress(
      currentIndex: 0,
      completedCount: total,
      completed: true,
    );
    _lastActiveTitle = title;
    _persist();
    notifyListeners();
  }

  void resetSublistProgress(String title) {
    _sublistProgress[title] = const SublistProgress.empty();
    _persist();
    notifyListeners();
  }

  // ----- API: stars -----
  bool isStarred(int wordId) => _starred.contains(wordId);

  void toggleStar(int wordId) {
    if (!_starred.add(wordId)) {
      _starred.remove(wordId);
    }
    _persist();
    notifyListeners();
  }

  List<Word> starredWords(Iterable<Word> all) {
    final list = all.where((w) => _starred.contains(w.id)).toList();
    list.sort((a, b) => a.english.compareTo(b.english));
    return list;
  }

  int get starredCount => _starred.length;

  // ----- API: stats -----
  int get streakDays => _streakDays;
  int get totalMastered => _totalMastered;
  int get totalAttempts => _totalAttempts;
  int get totalCorrect => _totalCorrect;
  double get accuracy =>
      _totalAttempts == 0 ? 0 : _totalCorrect / _totalAttempts;
  int get pendingMistakes => _mistakeCounts.length;

  void recordAttempt({required bool correct}) {
    _totalAttempts++;
    if (correct) _totalCorrect++;
    _bumpStreakForToday();
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _dailyHistory[today] = (_dailyHistory[today] ?? 0) + 1;
    _persist();
    notifyListeners();
  }

  void _bumpStreakForToday() {
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    if (_lastStudyDate == today) return;
    if (_lastStudyDate != null) {
      final last = DateTime.tryParse(_lastStudyDate!);
      if (last != null) {
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(last.year, last.month, last.day))
            .inDays;
        if (diff == 1) {
          _streakDays++;
        } else if (diff > 1) {
          _streakDays = 1;
        }
      } else {
        _streakDays = 1;
      }
    } else {
      _streakDays = 1;
    }
    _lastStudyDate = today;
  }
}

// ============================================================
// App
// ============================================================

class WordApp extends StatelessWidget {
  const WordApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme.apply(
        bodyColor: AppTheme.textPrimary,
        displayColor: AppTheme.textPrimary,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: base.colorScheme.copyWith(
          primary: AppTheme.primary,
          surface: Colors.white,
        ),
        textTheme: textTheme,
        // Standard Apple right-to-left slide for page transitions.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeShell(),
    );
  }
}

// ============================================================
// Bottom-nav shell (学习 / 统计)
// ============================================================

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: const <Widget>[
            SublistSelectionPage(),
            StatsPage(),
          ],
        ),
        bottomNavigationBar: _GlassBottomNav(
          index: _index,
          onChanged: (i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          },
        ),
      ),
    );
  }
}

/// Apple-style slim tab bar. Targets ~52pt content height (matches iOS
/// system tab bar) with a subtle frosted card and gentle iOS-style icon
/// + caption stack.
class _GlassBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _GlassBottomNav({required this.index, required this.onChanged});

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 0.5,
                  ),
                ),
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

// ============================================================
// Sublist selection (学习 tab)
// ============================================================

class SublistSelectionPage extends StatefulWidget {
  const SublistSelectionPage({super.key});

  @override
  State<SublistSelectionPage> createState() => _SublistSelectionPageState();
}

class _SublistSelectionPageState extends State<SublistSelectionPage> {
  List<Map<String, dynamic>> awlSublists = <Map<String, dynamic>>[];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final jsonString = await rootBundle.loadString('assets/words.json');
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final loaded = jsonList.map((sublist) {
        final words = (sublist['words'] as List<dynamic>)
            .map((item) => Word.fromJson(item as Map<String, dynamic>))
            .toList();
        StudyManager.instance.applyMistakeCounts(words);
        return <String, dynamic>{
          'title': sublist['title'] as String,
          'words': words,
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        awlSublists = loaded;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Word> get _allWords => awlSublists
      .expand<Word>((s) => List<Word>.from(s['words'] as List))
      .toList();

  ({String title, int total, int completed, double ratio}) _todayPlan() {
    if (awlSublists.isEmpty) {
      return (title: '—', total: 0, completed: 0, ratio: 0);
    }
    final mgr = StudyManager.instance;

    ({String title, int total, int completed, double ratio}) _packFor(
      Map<String, dynamic> sublist,
    ) {
      final title = sublist['title'] as String;
      final total = (sublist['words'] as List).length;
      final progress = mgr.progressFor(title);
      final rawCompleted =
          progress.completed ? total : progress.completedCount;
      final completed = rawCompleted.clamp(0, total);
      return (
        title: title,
        total: total,
        completed: completed,
        ratio: total == 0 ? 0.0 : completed / total,
      );
    }

    // 1) Prefer the most recently active sublist — that's what the user is
    //    currently studying, so the Today's Plan card should reflect its
    //    progress (not stale progress on Sublist 1).
    final activeTitle = mgr.lastActiveTitle;
    if (activeTitle != null) {
      for (final sublist in awlSublists) {
        if (sublist['title'] == activeTitle) {
          return _packFor(sublist);
        }
      }
    }

    // 2) Otherwise pick the first in-progress (not completed) sublist.
    for (final sublist in awlSublists) {
      final title = sublist['title'] as String;
      final progress = mgr.progressFor(title);
      if (progress.completed) continue;
      if (progress.completedCount > 0 || progress.currentIndex > 0) {
        return _packFor(sublist);
      }
    }

    // 3) Fall back to the first sublist (zero progress).
    return _packFor(awlSublists.first);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyManager.instance,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : awlSublists.isEmpty
                  ? const Center(child: Text('No data found.'))
                  : _buildContent(context),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final today = _todayPlan();
    final reviewCount = StudyManager.instance.pendingMistakes;
    final starCount = StudyManager.instance.starredCount;
    final srsCount = StudyManager.instance.srsDueCount(_allWords);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text(
                        'Select Sublist',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Pick a list and start your focus session.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: CupertinoIcons.clock,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute<void>(
                        builder: (_) =>
                            ForgottenWordsPage(sublists: awlSublists),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _TodayPlanCard(plan: today),
          ),
        ),
        // SRS smart review pill
        if (srsCount > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _SrsReviewPill(
                count: srsCount,
                onTap: () {
                  final due = StudyManager.instance.srsDueWords(_allWords);
                  Navigator.push(
                    context,
                    CupertinoPageRoute<void>(
                      builder: (_) => StudyPage(
                        title: '间隔复习',
                        words: due,
                        reviewMode: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _ShortcutTile(
                    icon: CupertinoIcons.refresh_thick,
                    title: '今日复习',
                    subtitle: reviewCount == 0
                        ? '暂无错题'
                        : '$reviewCount 个待巩固',
                    color: AppTheme.danger,
                    onTap: reviewCount == 0
                        ? null
                        : () {
                            final wrong = StudyManager.instance
                                .forgottenWords(_allWords);
                            Navigator.push(
                              context,
                              CupertinoPageRoute<void>(
                                builder: (_) => StudyPage(
                                  title: '今日复习',
                                  words: wrong,
                                  reviewMode: true,
                                ),
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutTile(
                    icon: CupertinoIcons.star_fill,
                    title: '我的收藏',
                    subtitle:
                        starCount == 0 ? '暂无收藏' : '$starCount 个单词',
                    color: AppTheme.star,
                    onTap: starCount == 0
                        ? null
                        : () {
                            final stars = StudyManager.instance
                                .starredWords(_allWords);
                            Navigator.push(
                              context,
                              CupertinoPageRoute<void>(
                                builder: (_) => StudyPage(
                                  title: '我的收藏',
                                  words: stars,
                                  reviewMode: true,
                                ),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 86),
          sliver: SliverList.builder(
            itemCount: awlSublists.length,
            itemBuilder: (context, index) {
              final sublist = awlSublists[index];
              final title = sublist['title'] as String;
              final words = List<Word>.from(sublist['words'] as List);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SublistTile(
                  index: index + 1,
                  title: title,
                  words: words,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      CupertinoPageRoute<void>(
                        builder: (_) => StudyPage(title: title, words: words),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 18,
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final ({String title, int total, int completed, double ratio}) plan;
  const _TodayPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final percent = (plan.ratio * 100).round();
    return GlassCard(
      opacity: 0.75,
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text(
                      "Today's Plan",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '· ${plan.title}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    children: <InlineSpan>[
                      TextSpan(text: '${plan.completed}'),
                      TextSpan(
                        text: '/${plan.total} words',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: plan.ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Keep going — every word counts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _RingProgress(value: plan.ratio, percent: percent),
        ],
      ),
    );
  }
}

class _RingProgress extends StatelessWidget {
  final double value;
  final int percent;
  const _RingProgress({required this.value, required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: 64,
            height: 64,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 6,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SrsReviewPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _SrsReviewPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.clock_fill,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count 个单词待间隔复习',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'SRS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SublistTile extends StatelessWidget {
  final int index;
  final String title;
  final List<Word> words;
  final VoidCallback onTap;

  const _SublistTile({
    required this.index,
    required this.title,
    required this.words,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = words.length;
    final progress = StudyManager.instance.progressFor(title);
    final completed =
        progress.completed ? total : progress.completedCount.clamp(0, total);
    final ratio = total == 0 ? 0.0 : completed / total;

    String status = 'Not started';
    if (progress.completed) {
      status = 'Completed';
    } else if (completed > 0) {
      status = 'In progress';
    }

    return ScaleTap(
      onTap: onTap,
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFEDEBFF), Color(0xFFDFDBFF)],
                ),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$total words · $status',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.10),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Stats page
// ============================================================

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyManager.instance,
      builder: (context, _) {
        final mgr = StudyManager.instance;
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 86),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Your Stats',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A small look at your progress.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _StreakCard(days: mgr.streakDays),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        icon: CupertinoIcons.checkmark_seal_fill,
                        color: AppTheme.success,
                        value: '${mgr.totalMastered}',
                        label: '已掌握',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: CupertinoIcons.flame_fill,
                        color: AppTheme.danger,
                        value: '${mgr.pendingMistakes}',
                        label: '待复习',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MetricCard(
                  icon: CupertinoIcons.chart_pie_fill,
                  color: AppTheme.primary,
                  value: mgr.totalAttempts == 0
                      ? '—'
                      : '${(mgr.accuracy * 100).round()}%',
                  label:
                      '准确率 (共 ${mgr.totalAttempts} 次拼写, ${mgr.totalCorrect} 次正确)',
                  wide: true,
                ),
                const SizedBox(height: 14),
                _MetricCard(
                  icon: CupertinoIcons.star_fill,
                  color: AppTheme.star,
                  value: '${mgr.starredCount}',
                  label: '我的收藏',
                  wide: true,
                ),
                const SizedBox(height: 24),
                _WeeklyChart(history: mgr.dailyHistory),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<String, int> history;
  const _WeeklyChart({required this.history});

  List<_DayBar> _buildBars() {
    final bars = <_DayBar>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final count = history[key] ?? 0;
      final labels = ['一', '二', '三', '四', '五', '六', '日'];
      // dart weekday: 1=Mon ... 7=Sun
      bars.add(_DayBar(
        label: labels[d.weekday - 1],
        count: count,
        isToday: i == 0,
      ));
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final bars = _buildBars();
    final maxCount = bars.fold<int>(1, (m, b) => b.count > m ? b.count : m);

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(CupertinoIcons.chart_bar_fill,
                  size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                '本周学习',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxCount + 1).toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${rod.toY.toInt()} 次',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= bars.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            bars[idx].label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  bars[idx].isToday ? FontWeight.w700 : FontWeight.w500,
                              color: bars[idx].isToday
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(bars.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: bars[i].count.toDouble(),
                        color: bars[i].isToday
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.45),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar {
  final String label;
  final int count;
  final bool isToday;
  const _DayBar({required this.label, required this.count, required this.isToday});
}

class _StreakCard extends StatelessWidget {
  final int days;
  const _StreakCard({required this.days});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 0.75,
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFFB75E), Color(0xFFED8F03)],
              ),
            ),
            child: const Icon(
              CupertinoIcons.flame_fill,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$days 天',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '连续学习',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool wide;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 22,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Study page
// ============================================================

class StudyPage extends StatefulWidget {
  final String title;
  final List<Word> words;
  final bool reviewMode;

  const StudyPage({
    super.key,
    required this.title,
    required this.words,
    this.reviewMode = false,
  });

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final ConfettiController _confetti;

  late List<Word> studyList;
  int currentIndex = 0;
  int _direction = 1; // 1 = next, -1 = previous (drives flashcard arc dir)
  bool hasChecked = false;
  bool isCorrect = false;
  bool showHint = false;
  // True once the sublist's last word has been completed in this session.
  // Used to (a) gate the input/Check button, (b) prevent dispose() from
  // overwriting `completed: true` with a `currentIndex: last` snapshot.
  bool _sessionCompleted = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _confetti =
        ConfettiController(duration: const Duration(milliseconds: 1500));
    studyList = List<Word>.from(widget.words);
    StudyManager.instance.applyMistakeCounts(studyList);
    if (widget.reviewMode) {
      currentIndex = 0;
    } else {
      currentIndex = StudyManager.instance.startOrResumeSublist(
        widget.title,
        studyList.length,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 不自动弹出键盘，用户点击输入框时再弹出
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _checkSpelling() {
    if (_sessionCompleted) return;
    if (_inputController.text.trim().isEmpty || hasChecked) return;
    final word = studyList[currentIndex];
    final input = _inputController.text.trim().toLowerCase();
    final correct = word.english.toLowerCase();

    setState(() {
      hasChecked = true;
      isCorrect = input == correct;
    });

    StudyManager.instance.recordAttempt(correct: isCorrect);

    if (isCorrect) {
      HapticFeedback.lightImpact();
      // 在复习模式下答对就把这个错题清除
      if (widget.reviewMode) {
        StudyManager.instance.removeMistake(word.id);
      }
    } else {
      HapticFeedback.heavyImpact();
      StudyManager.instance.recordMistake(word);
    }

    if (!widget.reviewMode) {
      StudyManager.instance.saveCurrentPosition(
        widget.title,
        currentIndex: currentIndex,
        totalWords: studyList.length,
      );
    }
  }

  void _nextWord() {
    if (_sessionCompleted) return;
    HapticFeedback.selectionClick();
    if (currentIndex < studyList.length - 1) {
      setState(() {
        _direction = 1;
        currentIndex++;
        _resetState();
      });
      if (!widget.reviewMode) {
        StudyManager.instance.saveCurrentPosition(
          widget.title,
          currentIndex: currentIndex,
          totalWords: studyList.length,
        );
      }
    } else {
      // Lock the page before showing the celebration: drop focus, disable
      // input, and remember we're done so dispose() doesn't roll back the
      // "completed: true" state we're about to write.
      _focusNode.unfocus();
      setState(() {
        _sessionCompleted = true;
        hasChecked = true;
      });
      if (!widget.reviewMode) {
        StudyManager.instance
            .markSublistCompleted(widget.title, studyList.length);
      }
      _celebrateAndExit();
    }
  }

  void _prevWord() {
    if (currentIndex == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _direction = -1;
      currentIndex--;
      _resetState();
    });
    if (!widget.reviewMode) {
      StudyManager.instance.saveCurrentPosition(
        widget.title,
        currentIndex: currentIndex,
        totalWords: studyList.length,
      );
    }
  }

  void _resetState() {
    _inputController.clear();
    hasChecked = false;
    isCorrect = false;
    showHint = false;
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _celebrateAndExit() {
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.heavyImpact();
    });
    _confetti.play();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _CompletionDialog(
        title: widget.title,
        reviewMode: widget.reviewMode,
        onClose: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStarToast({required bool starred}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(80, 0, 80, 110),
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 1400),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.textPrimary.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                starred ? CupertinoIcons.star_fill : CupertinoIcons.star,
                size: 16,
                color: starred ? AppTheme.star : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                starred ? '已收藏' : '已取消收藏',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset progress?'),
        content: Text('This will clear progress for ${widget.title}.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              StudyManager.instance.resetSublistProgress(widget.title);
              Navigator.pop(ctx);
              setState(() {
                currentIndex = 0;
                _resetState();
              });
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Don't write a position snapshot if we already marked the sublist as
    // completed — otherwise it overwrites `completed: true / 60/60` with
    // `completed: false / 59/60` and the next entry resumes on the last
    // word with input still active.
    if (!widget.reviewMode && !_sessionCompleted) {
      StudyManager.instance.saveCurrentPosition(
        widget.title,
        currentIndex: currentIndex,
        totalWords: studyList.length,
      );
    }
    _inputController.dispose();
    _focusNode.dispose();
    flutterTts.stop();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (studyList.isEmpty) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: const Center(child: Text('No words.')),
        ),
      );
    }

    final word = studyList[currentIndex];
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildProgressCard(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _FlashcardSwitcher(
                        direction: _direction,
                        currentKey: ValueKey<int>(currentIndex),
                        onSwipeRight: () {
                          if (currentIndex > 0) _prevWord();
                        },
                        onSwipeLeft: () {
                          if (hasChecked) _nextWord();
                        },
                        child: _buildWordCard(word),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(
                        bottom: keyboardInset > 0 ? 8 : 0,
                      ),
                      child: _buildInputAndButton(word),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Confetti overlay (top-center, falls down)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: pi / 2,
                  emissionFrequency: 0.08,
                  numberOfParticles: 18,
                  maxBlastForce: 20,
                  minBlastForce: 6,
                  gravity: 0.4,
                  shouldLoop: false,
                  colors: const <Color>[
                    AppTheme.primary,
                    AppTheme.success,
                    AppTheme.star,
                    Color(0xFFFF6B9D),
                    Color(0xFF89B4FF),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        CircleIconButton(
          icon: CupertinoIcons.back,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Center(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
        if (widget.reviewMode)
          const SizedBox(width: 40)
        else
          CircleIconButton(
            icon: CupertinoIcons.refresh,
            onTap: _confirmReset,
          ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final ratio = (currentIndex + 1) / studyList.length;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFEDEBFF), Color(0xFFDFDBFF)],
              ),
            ),
            child: const Icon(
              CupertinoIcons.book,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Word ${currentIndex + 1} of ${studyList.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 5,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.reviewMode ? '复习模式' : 'Auto-saving progress',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(ratio * 100).round()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Word word) {
    final maskedExample = word.example.isEmpty
        ? null
        : word.example.replaceAll(
            RegExp(word.english, caseSensitive: false),
            '____',
          );
    final showResult = hasChecked;
    final starred = StudyManager.instance.isStarred(word.id);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: GlassCard(
        opacity: 0.75,
        radius: 26,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: StarToggleButton(
                starred: starred,
                onTap: () {
                  final wasStarred =
                      StudyManager.instance.isStarred(word.id);
                  StudyManager.instance.toggleStar(word.id);
                  // Force StudyPage rebuild — it doesn't subscribe to
                  // StudyManager directly, so the icon/color won't refresh
                  // without an explicit setState.
                  setState(() {});
                  _showStarToast(starred: !wasStarred);
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              word.chinese,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (word.phonetic.isNotEmpty)
                  Text(
                    word.phonetic,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _speak(word.english),
                  child: const Icon(
                    CupertinoIcons.speaker_2_fill,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            if (showResult) ...<Widget>[
              const SizedBox(height: 22),
              _buildResultBlock(word),
            ],
            if (maskedExample != null) ...<Widget>[
              const SizedBox(height: 22),
              Container(
                height: 1,
                color: AppTheme.textSecondary.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 18),
              Text(
                maskedExample,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textPrimary.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultBlock(Word word) {
    if (isCorrect) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: AppTheme.success,
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            'Excellent',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        const Text(
          'Correct spelling',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          word.english,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.danger,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInputAndButton(Word word) {
    final hint = showHint
        ? '${word.english[0]}${'·' * (word.english.length - 1)}'
        : 'Type spelling here…';
    return Column(
      children: <Widget>[
        GlassCard(
          radius: 28,
          opacity: 0.6,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TextField(
            controller: _inputController,
            focusNode: _focusNode,
            enabled: !hasChecked && !_sessionCompleted,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              letterSpacing: 0.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: InputBorder.none,
              suffixIcon: hasChecked
                  ? null
                  : IconButton(
                      icon: const Icon(
                        CupertinoIcons.lightbulb,
                        color: AppTheme.primary,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => showHint = true);
                      },
                    ),
            ),
            onSubmitted: (_) => _checkSpelling(),
          ),
        ),
        const SizedBox(height: 14),
        DuolingoButton(
          label: _sessionCompleted
              ? '已完成'
              : (hasChecked ? 'Next' : 'Check'),
          icon: _sessionCompleted
              ? CupertinoIcons.checkmark_alt
              : (hasChecked ? CupertinoIcons.arrow_right : null),
          onTap: _sessionCompleted
              ? null
              : (hasChecked ? _nextWord : _checkSpelling),
          enabled: !_sessionCompleted,
          color: hasChecked
              ? (isCorrect ? AppTheme.success : AppTheme.primary)
              : AppTheme.primary,
          shadowColor: hasChecked
              ? (isCorrect ? AppTheme.successDark : AppTheme.primaryDark)
              : AppTheme.primaryDark,
          height: 54,
          radius: 18,
        ),
      ],
    );
  }
}

// ============================================================
// Completion dialog — Apple-style sublist finish celebration
// ============================================================

class _CompletionDialog extends StatefulWidget {
  final String title;
  final bool reviewMode;
  final VoidCallback onClose;

  const _CompletionDialog({
    required this.title,
    required this.reviewMode,
    required this.onClose,
  });

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog>
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
          // easeOutBack overshoots gently; clamp anything we feed into shadow
          // values so we never produce negative blur radii.
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
        // Two staged eases: badge pop, then expanding glow ring underneath.
        final pop = Curves.easeOutBack.transform(t);
        final ringT = Curves.easeOutCubic.transform(t);
        // pop can briefly exceed 1.0 — clamp where shadows depend on it.
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
              // Expanding glow ring (no boxShadow blur — pure decoration)
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
              // Solid badge (no animated shadow → no negative-blur risk)
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

// ============================================================
// Flashcard switcher — card-deck arc trajectory
// ============================================================

class _FlashcardSwitcher extends StatefulWidget {
  final Widget child;
  final ValueKey<int> currentKey;
  final int direction; // 1 = forward (from right), -1 = backward (from left)
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _FlashcardSwitcher({
    required this.child,
    required this.currentKey,
    required this.direction,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<_FlashcardSwitcher> createState() => _FlashcardSwitcherState();
}

class _FlashcardSwitcherState extends State<_FlashcardSwitcher>
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
  void didUpdateWidget(covariant _FlashcardSwitcher oldWidget) {
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

          // Old card exits — curving off to the opposite side
          if (_oldChild != null && _ctrl.value < 1.0) {
            final sign = _lastDir > 0 ? -1.0 : 1.0; // old goes opposite
            final x = sign * 0.75 * curved * w;
            final y = 0.06 * curved * curved * h; // gentle downward arc
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

          // New card enters from the side with an arc
          final inSign = _lastDir > 0 ? 1.0 : -1.0;
          final rev = 1.0 - curved; // 1→0 → card travels from off-screen to center
          final ix = inSign * 0.75 * rev * w;
          final iy = -0.07 * rev * h; // starts above, settles down
          final iangle = inSign * 0.18 * rev;
          final iscale = 0.94 + 0.06 * curved; // scales up slightly as it arrives

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

// ============================================================
// Forgotten words page (kept, restyled)
// ============================================================

class ForgottenWordsPage extends StatefulWidget {
  final List<Map<String, dynamic>> sublists;
  const ForgottenWordsPage({super.key, required this.sublists});

  @override
  State<ForgottenWordsPage> createState() => _ForgottenWordsPageState();
}

class _ForgottenWordsPageState extends State<ForgottenWordsPage> {
  String? selectedSublist;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyManager.instance,
      builder: (context, _) {
        List<Word> allWords = <Word>[];
        if (selectedSublist == null) {
          allWords = widget.sublists
              .expand<Word>((s) => List<Word>.from(s['words'] as List))
              .toList();
        } else {
          final sublist = widget.sublists
              .firstWhere((s) => s['title'] == selectedSublist);
          allWords = List<Word>.from(sublist['words'] as List);
        }

        final words = StudyManager.instance.forgottenWords(allWords);

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CircleIconButton(
                          icon: CupertinoIcons.back,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Missed Words',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (widget.sublists.isNotEmpty) _buildFilterChips(),
                    const SizedBox(height: 14),
                    Expanded(
                      child: words.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: words.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _MissedWordTile(word: words[index]),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          _chip('All', selectedSublist == null,
              () => setState(() => selectedSublist = null)),
          ...widget.sublists.map((s) {
            final title = s['title'] as String;
            final selected = selectedSublist == title;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _chip(title, selected,
                  () => setState(() => selectedSublist = title)),
            );
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.7),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.6),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.success.withValues(alpha: 0.12),
            ),
            child: const Icon(
              CupertinoIcons.checkmark_seal,
              color: AppTheme.success,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'All clear',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No missed words yet — keep going.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MissedWordTile extends StatelessWidget {
  final Word word;
  const _MissedWordTile({required this.word});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  word.english,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '× ${word.errorCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.danger,
                  ),
                ),
              ),
            ],
          ),
          if (word.phonetic.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              word.phonetic,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: AppTheme.textSecondary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 10),
          Text(
            word.chinese,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ScaleTap(
              onTap: () => StudyManager.instance.removeMistake(word.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 14,
                      color: AppTheme.success,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Mastered',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
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
  }
}
