import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/study_manager.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/glass_card.dart';
import 'study_page.dart';
import 'forgotten_words.dart';

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

    ({String title, int total, int completed, double ratio}) packFor(
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

    final activeTitle = mgr.lastActiveTitle;
    if (activeTitle != null) {
      for (final sublist in awlSublists) {
        if (sublist['title'] == activeTitle) {
          return packFor(sublist);
        }
      }
    }

    for (final sublist in awlSublists) {
      final title = sublist['title'] as String;
      final progress = mgr.progressFor(title);
      if (progress.completed) continue;
      if (progress.completedCount > 0 || progress.currentIndex > 0) {
        return packFor(sublist);
      }
    }

    return packFor(awlSublists.first);
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
                  child:
                      CircularProgressIndicator(color: AppTheme.primary),
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
        if (srsCount > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _SrsReviewPill(
                count: srsCount,
                onTap: () {
                  final due =
                      StudyManager.instance.srsDueWords(_allWords);
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
                        builder: (_) =>
                            StudyPage(title: title, words: words),
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
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.12),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
