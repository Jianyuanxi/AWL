import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/study_manager.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../widgets/background.dart';
import '../widgets/buttons.dart';
import '../widgets/glass_card.dart';

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
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child:
                                      _MissedWordTile(word: words[index]),
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
          if (word.chinese.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              word.chinese,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
