import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/study_manager.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../widgets/background.dart';
import '../widgets/buttons.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/flashcard_switcher.dart';
import '../widgets/glass_card.dart';
import '../widgets/star_toggle.dart';

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
  int _direction = 1;
  bool hasChecked = false;
  bool isCorrect = false;
  bool showHint = false;
  bool _sessionCompleted = false;
  bool _showConfetti = false;

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
      if (StudyManager.instance.isAllWordsReviewed(widget.title)) {
        hasChecked = true;
        isCorrect = true;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {});
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
      // Last word in normal mode: hand off to Finish button
      if (!widget.reviewMode) return;
      _focusNode.unfocus();
      setState(() {
        _sessionCompleted = true;
        hasChecked = true;
      });
      _celebrateAndExit();
    }
  }

  void _finishSession() {
    if (_sessionCompleted) return;
    _focusNode.unfocus();
    setState(() => _sessionCompleted = true);
    StudyManager.instance.markSublistCompleted(widget.title, studyList.length);
    _celebrateAndExit();
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
    setState(() => _showConfetti = true);
    _confetti.play();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showConfetti = false);
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => CompletionDialog(
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                hasChecked = false;
                isCorrect = false;
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
    if (!widget.reviewMode && !_sessionCompleted) {
      if (hasChecked && currentIndex == studyList.length - 1) {
        StudyManager.instance.markAllWordsReviewed(
          widget.title,
          currentIndex,
          studyList.length,
        );
      } else {
        StudyManager.instance.saveCurrentPosition(
          widget.title,
          currentIndex: currentIndex,
          totalWords: studyList.length,
        );
      }
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
                      child: FlashcardSwitcher(
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
              if (_showConfetti)
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
                      widget.reviewMode
                          ? '复习模式'
                          : 'Auto-saving progress',
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
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
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
          style:
              TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
          opacity: 0.72,
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        Builder(builder: (context) {
          final isLastWord = currentIndex == studyList.length - 1;
          final showFinish =
              !widget.reviewMode && hasChecked && isLastWord && !_sessionCompleted;
          final String label = _sessionCompleted
              ? '已完成'
              : (showFinish ? 'Finish' : (hasChecked ? 'Next' : 'Check'));
          final IconData? icon = _sessionCompleted
              ? CupertinoIcons.checkmark_alt
              : (showFinish
                  ? CupertinoIcons.checkmark_seal
                  : (hasChecked ? CupertinoIcons.arrow_right : null));
          final VoidCallback? action = _sessionCompleted
              ? null
              : (showFinish
                  ? _finishSession
                  : (hasChecked ? _nextWord : _checkSpelling));
          return DuolingoButton(
            label: label,
            icon: icon,
            onTap: action,
            enabled: !_sessionCompleted,
            color: hasChecked
                ? (isCorrect ? AppTheme.success : AppTheme.primary)
                : AppTheme.primary,
            shadowColor: hasChecked
                ? (isCorrect ? AppTheme.successDark : AppTheme.primaryDark)
                : AppTheme.primaryDark,
            height: 54,
            radius: 18,
          );
        }),
      ],
    );
  }
}
