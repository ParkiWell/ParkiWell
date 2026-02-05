import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkinson/Firebase/firebase_cloud.dart';
import 'package:parkinson/routes.dart';
import 'package:parkinson/singleton.dart';
import 'package:parkinson/theme/app_theme.dart';

import 'Firebase/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final singleton = Singleton();
  
  await SharedPreferences.getInstance().then((prefs) async {
    if (prefs.containsKey('userID')) {
      await FirebaseCloud().getUser();
    } else {
      singleton.setFirstTime(true);
    }
    if (prefs.containsKey('theme')) {
      singleton.switchColorTheme(await singleton.getTheme());
    } else {
      singleton.switchColorTheme(false);
    }
  });
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final singleton = Singleton();

  @override
  void initState() {
    super.initState();
    singleton.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    singleton.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update system UI overlay style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      singleton.colorMode == 0
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppTheme.lightColors.navBackground,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppTheme.darkColors.navBackground,
            ),
    );

    return MaterialApp(
      title: 'Levio',
      routes: singleton.firstTime ? editProfileRoutes : screenRoutes,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: singleton.colorMode == 0 ? ThemeMode.light : ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
