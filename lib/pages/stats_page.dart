import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/study_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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
                              fontWeight: bars[idx].isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
  const _DayBar(
      {required this.label, required this.count, required this.isToday});
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
