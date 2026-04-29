import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sublist_progress.dart';
import 'word.dart';

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
  final Map<int, String> _mistakeDates = <int, String>{};
  final Map<String, SublistProgress> _sublistProgress =
      <String, SublistProgress>{};
  final Set<int> _starred = <int>{};
  final Map<String, int> _dailyHistory = <String, int>{};

  int _streakDays = 0;
  String? _lastStudyDate;
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
