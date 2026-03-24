import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const ProviderScope(
      child: NibbleApp(),
    ),
  );
}

class NibbleApp extends StatelessWidget {
  const NibbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nibble',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
