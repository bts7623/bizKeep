import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/image_paths.dart';
import 'core/theme.dart';
import 'features/list/list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ImagePaths.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarBrightness: Brightness.light, statusBarIconBrightness: Brightness.dark));
  runApp(const ProviderScope(child: BizKeepApp()));
}

class BizKeepApp extends StatelessWidget {
  const BizKeepApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizKeep',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const ListScreen(),
    );
  }
}
