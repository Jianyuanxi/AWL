import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/home_shell.dart';
import 'theme/app_theme.dart';

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
