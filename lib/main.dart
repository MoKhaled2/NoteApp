import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
// for firebase
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
//dark mode
import 'core/theme/theme_provider.dart';

void main() async {
  // لازم تتحط وتبدأ تجهز flutter
  WidgetsFlutterBinding.ensureInitialized();
  // بنشغل firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      // title
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      // light and dark theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // router
      routerConfig: router,
    );
  }
}
