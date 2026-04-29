import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'models/study_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudyManager.instance.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const WordApp());
}
