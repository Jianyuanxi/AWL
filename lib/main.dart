import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  static const Color primarySoft = Color(0xFF8F88FF);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color success = Color(0xFF34C759);
  static const Color danger = Color(0xFFFF3B30);

  static const List<Color> bgGradient = <Color>[
    Color(0xFFF8F9FB),
    Color(0xFFEEF1F6),
  ];

  static const List<Color> primaryGradient = <Color>[
    Color(0xFF8F88FF),
    Color(0xFF6C63FF),
  ];
}

// ============================================================
// Reusable widgets
// ============================================================

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.bgGradient,
        ),
      ),
      child: child,
    );
  }
}

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
    this.opacity = 0.6,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
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
          ),
        ),
      ),
    );
  }
}

class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleTap({super.key, required this.child, this.onTap});

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// Custom page route — fade + soft scale (no harsh slide).
// Forward feels like the destination "rises into focus", reverse settles back.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({required this.builder, RouteSettings? settings})
      : super(
          settings: settings,
          pageBuilder: (context, _, __) => builder(context),
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          opaque: true,
          barrierColor: null,
        );

  final WidgetBuilder builder;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.4).animate(cover),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.97).animate(cover),
        child: FadeTransition(
          opacity: enter,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(enter),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(enter),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// Page transitions builder used at the theme level so any default
// MaterialPageRoute (e.g. dialogs) gets the same smooth feel.
class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.4).animate(cover),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.97).animate(cover),
        child: FadeTransition(
          opacity: enter,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(enter),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(enter),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
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
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }
}

// ============================================================
// Models & State
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

class StudyManager extends ChangeNotifier {
  StudyManager._();

  static final StudyManager instance = StudyManager._();

  static const String _mistakeCountsKey = 'mistake_counts_v1';
  static const String _sublistProgressKey = 'sublist_progress_v1';

  late final SharedPreferences _prefs;
  bool _isReady = false;

  final Map<int, int> _mistakeCounts = <int, int>{};
  final Map<String, SublistProgress> _sublistProgress =
      <String, SublistProgress>{};

  Future<void> init() async {
    if (_isReady) return;
    _prefs = await SharedPreferences.getInstance();
    _loadMistakeCounts();
    _loadSublistProgress();
    _isReady = true;
  }

  void _loadMistakeCounts() {
    final raw = _prefs.getString(_mistakeCountsKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _mistakeCounts
      ..clear()
      ..addEntries(decoded.entries.map(
        (entry) => MapEntry(
          int.tryParse(entry.key) ?? 0,
          (entry.value as num).toInt(),
        ),
      ));
    _mistakeCounts.remove(0);
  }

  void _loadSublistProgress() {
    final raw = _prefs.getString(_sublistProgressKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _sublistProgress
      ..clear()
      ..addEntries(decoded.entries.map(
        (entry) => MapEntry(
          entry.key,
          SublistProgress.fromJson(entry.value as Map<String, dynamic>),
        ),
      ));
  }

  void _persist() {
    final mistakePayload = <String, int>{
      for (final entry in _mistakeCounts.entries) '${entry.key}': entry.value,
    };
    final progressPayload = <String, Map<String, dynamic>>{
      for (final entry in _sublistProgress.entries)
        entry.key: entry.value.toJson(),
    };
    _prefs.setString(_mistakeCountsKey, jsonEncode(mistakePayload));
    _prefs.setString(_sublistProgressKey, jsonEncode(progressPayload));
  }

  void applyMistakeCounts(Iterable<Word> words) {
    for (final word in words) {
      word.errorCount = _mistakeCounts[word.id] ?? 0;
    }
  }

  void recordMistake(Word word) {
    final nextCount = (_mistakeCounts[word.id] ?? 0) + 1;
    _mistakeCounts[word.id] = nextCount;
    word.errorCount = nextCount;
    _persist();
    notifyListeners();
  }

  void removeMistake(int wordId) {
    _mistakeCounts.remove(wordId);
    _persist();
    notifyListeners();
  }

  List<Word> forgottenWords(Iterable<Word> allWords) {
    final words = allWords
        .where((w) => (_mistakeCounts[w.id] ?? 0) > 0)
        .map((w) {
      w.errorCount = _mistakeCounts[w.id] ?? 0;
      return w;
    }).toList();

    words.sort((a, b) {
      final c = b.errorCount.compareTo(a.errorCount);
      return c != 0 ? c : a.english.compareTo(b.english);
    });
    return words;
  }

  SublistProgress progressFor(String title) =>
      _sublistProgress[title] ?? const SublistProgress.empty();

  int startOrResumeSublist(String title, int totalWords) {
    if (totalWords <= 0) return 0;
    final progress = progressFor(title);
    if (progress.completed) {
      _sublistProgress[title] = const SublistProgress.empty();
      _persist();
      notifyListeners();
      return 0;
    }
    return progress.currentIndex.clamp(0, totalWords - 1);
  }

  void saveCurrentPosition(
    String title, {
    required int currentIndex,
    required int totalWords,
  }) {
    if (totalWords <= 0) return;
    final safeIndex = currentIndex.clamp(0, totalWords - 1);
    final previous = progressFor(title);
    final completedCount = max(
      previous.completed ? 0 : previous.completedCount,
      safeIndex,
    ).clamp(0, totalWords);

    _sublistProgress[title] = SublistProgress(
      currentIndex: safeIndex,
      completedCount: completedCount,
      completed: false,
    );
    _persist();
    notifyListeners();
  }

  void markSublistCompleted(String title, int totalWords) {
    _sublistProgress[title] = SublistProgress(
      currentIndex: 0,
      completedCount: totalWords,
      completed: true,
    );
    _persist();
    notifyListeners();
  }

  void resetSublistProgress(String title) {
    _sublistProgress[title] = const SublistProgress.empty();
    _persist();
    notifyListeners();
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: base.colorScheme.copyWith(
          primary: AppTheme.primary,
          surface: Colors.white,
        ),
        textTheme: base.textTheme.apply(
          bodyColor: AppTheme.textPrimary,
          displayColor: AppTheme.textPrimary,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            for (final p in TargetPlatform.values)
              p: const _SmoothPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SublistSelectionPage(),
    );
  }
}

// ============================================================
// Sublist selection page
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

  ({String title, int total, int completed, double ratio}) _todayPlan() {
    if (awlSublists.isEmpty) {
      return (title: '—', total: 0, completed: 0, ratio: 0);
    }
    for (final sublist in awlSublists) {
      final title = sublist['title'] as String;
      final total = (sublist['words'] as List).length;
      final progress = StudyManager.instance.progressFor(title);
      if (progress.completed) continue;
      if (progress.completedCount > 0 || progress.currentIndex > 0) {
        final completed = progress.completedCount.clamp(0, total);
        return (
          title: title,
          total: total,
          completed: completed,
          ratio: total == 0 ? 0 : completed / total,
        );
      }
    }
    final first = awlSublists.first;
    final title = first['title'] as String;
    final total = (first['words'] as List).length;
    return (title: title, total: total, completed: 0, ratio: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyManager.instance,
      builder: (context, _) {
        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    )
                  : awlSublists.isEmpty
                      ? const Center(child: Text('No data found.'))
                      : _buildContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final today = _todayPlan();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
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
                  icon: Icons.history_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute<void>(
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                      SmoothPageRoute<void>(
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Plan',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
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
        children: [
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
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFEDEBFF),
                    Color(0xFFDFDBFF),
                  ],
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
                children: [
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
// Study page
// ============================================================

class StudyPage extends StatefulWidget {
  final String title;
  final List<Word> words;

  const StudyPage({super.key, required this.title, required this.words});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late List<Word> studyList;
  int currentIndex = 0;
  bool hasChecked = false;
  bool isCorrect = false;
  bool showHint = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    studyList = List<Word>.from(widget.words);
    StudyManager.instance.applyMistakeCounts(studyList);
    currentIndex = StudyManager.instance.startOrResumeSublist(
      widget.title,
      studyList.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
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
    if (_inputController.text.trim().isEmpty || hasChecked) return;
    final currentWord = studyList[currentIndex];
    final userInput = _inputController.text.trim().toLowerCase();
    final correctSpell = currentWord.english.toLowerCase();

    setState(() {
      hasChecked = true;
      isCorrect = userInput == correctSpell;
    });

    if (!isCorrect) {
      StudyManager.instance.recordMistake(currentWord);
    }
    StudyManager.instance.saveCurrentPosition(
      widget.title,
      currentIndex: currentIndex,
      totalWords: studyList.length,
    );
  }

  void _nextWord() {
    if (currentIndex < studyList.length - 1) {
      setState(() {
        currentIndex++;
        _resetState();
      });
      StudyManager.instance.saveCurrentPosition(
        widget.title,
        currentIndex: currentIndex,
        totalWords: studyList.length,
      );
    } else {
      StudyManager.instance.markSublistCompleted(
        widget.title,
        studyList.length,
      );
      _showFinishDialog();
    }
  }

  void _prevWord() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _resetState();
      });
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

  void _showFinishDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Finished',
          style: TextStyle(
            color: AppTheme.success,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'You completed all words in this sublist. Progress saved.',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'Back to List',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Reset progress?'),
        content: Text('This will clear progress for ${widget.title}.'),
        actions: [
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
    StudyManager.instance.saveCurrentPosition(
      widget.title,
      currentIndex: currentIndex,
      totalWords: studyList.length,
    );
    _inputController.dispose();
    _focusNode.dispose();
    flutterTts.stop();
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
          body: const Center(child: Text('No words in this list.')),
        ),
      );
    }

    final currentWord = studyList[currentIndex];

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: 16),
                _buildProgressCard(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) > 300 &&
                            currentIndex > 0) {
                          _prevWord();
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 480),
                        reverseDuration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            ...previous,
                            if (current != null) current,
                          ],
                        ),
                        transitionBuilder: (child, anim) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.10, 0),
                            end: Offset.zero,
                          ).animate(anim);
                          final scale = Tween<double>(
                            begin: 0.96,
                            end: 1.0,
                          ).animate(anim);
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: slide,
                              child: ScaleTransition(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(currentIndex),
                          child: _buildWordCard(currentWord),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInputAndButton(currentWord),
                const SizedBox(height: 12),
              ],
            ),
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
                colors: <Color>[
                  Color(0xFFEDEBFF),
                  Color(0xFFDFDBFF),
                ],
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
                    const Text(
                      'Auto-saving progress',
                      style: TextStyle(
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

    return GlassCard(
      opacity: 0.75,
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              CupertinoIcons.star,
              size: 20,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
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
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
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
            enabled: !hasChecked,
            textAlign: TextAlign.start,
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
                      onPressed: () => setState(() => showHint = true),
                    ),
            ),
            onSubmitted: (_) => _checkSpelling(),
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: hasChecked ? 'Next' : 'Check',
          onTap: hasChecked ? _nextWord : _checkSpelling,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.primaryGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
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
                    if (widget.sublists.isNotEmpty)
                      _buildFilterChips(),
                    const SizedBox(height: 14),
                    Expanded(
                      child: words.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: words.length,
                              itemBuilder: (context, index) {
                                final word = words[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _MissedWordTile(word: word),
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
              child: _chip(
                title,
                selected,
                () => setState(() => selectedSublist = title),
              ),
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
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
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
