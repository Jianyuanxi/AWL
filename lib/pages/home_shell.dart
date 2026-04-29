import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/background.dart';
import '../widgets/bottom_nav.dart';
import 'sublist_selection.dart';
import 'stats_page.dart';

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
        bottomNavigationBar: GlassBottomNav(
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
