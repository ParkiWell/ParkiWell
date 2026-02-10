import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levio/Main/editProfile.dart';
import 'package:levio/navbar.dart';
import 'package:levio/routes.dart';
import 'package:levio/singleton.dart';
import 'package:levio/theme/app_theme.dart';
import 'package:levio/screens/splash_screen.dart';
import 'package:levio/screens/intro_screen.dart';
import 'package:levio/services/app_logger.dart';
import 'package:levio/config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terminate_restart/terminate_restart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine if running in production
  final bool isProduction = kReleaseMode || EnvironmentConfig.isProduction;

  // Initialize logger
  final logger = AppLogger();
  logger.init(isProduction: isProduction);
  logger.info(
      'App starting in ${isProduction ? "production" : "development"} mode');

  // Initialize restart functionality
  TerminateRestart.instance.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize singleton and database
  final singleton = Singleton();

  try {
    await singleton.initialize(isProduction: isProduction);

    await SharedPreferences.getInstance().then((prefs) async {
      if (prefs.containsKey('userID')) {
        try {
          // Load user from local database
          final loaded = await singleton.loadUser();
          if (loaded && singleton.name != "[Name]") {
            // User data loaded successfully, not first time
            singleton.setFirstTime(false);
            logger.info('Existing user loaded successfully');
          } else {
            // User data not found, clear stale userID
            await prefs.remove('userID');
            logger.info('Stale user ID cleared');
          }
        } catch (e, stackTrace) {
          // Error loading user, clear stale userID
          await prefs.remove('userID');
          logger.error('Error loading user', e, stackTrace);
        }
      }
      // firstTime remains true by default if no valid user found

      if (prefs.containsKey('theme')) {
        singleton.switchColorTheme(await singleton.getTheme());
      } else {
        singleton.switchColorTheme(false);
      }
    });
  } catch (e, stackTrace) {
    logger.fatal('Critical initialization error', e, stackTrace);
  }

  // Set up error handling for production
  if (isProduction) {
    FlutterError.onError = (details) {
      logger.fatal('Flutter error', details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logger.fatal('Platform error', error, stack);
      return true;
    };
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum AppScreen { splash, intro, editProfile, home }

class _MyAppState extends State<MyApp> {
  final singleton = Singleton();
  AppScreen _currentScreen = AppScreen.splash;

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

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        // If first time, show intro. Otherwise go to home.
        _currentScreen = singleton.firstTime ? AppScreen.intro : AppScreen.home;
      });
    }
  }

  void _onIntroComplete() {
    if (mounted) {
      setState(() {
        _currentScreen = AppScreen.editProfile;
      });
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

    Widget home;
    switch (_currentScreen) {
      case AppScreen.splash:
        home = SplashScreen(onComplete: _onSplashComplete);
        break;
      case AppScreen.intro:
        home = IntroScreen(onComplete: _onIntroComplete);
        break;
      case AppScreen.editProfile:
        home = const EditProfileScreen();
        break;
      case AppScreen.home:
        home = const Navbar();
        break;
    }

    return MaterialApp(
      title: 'Levio',
      routes: namedRoutes,
      home: home,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: singleton.colorMode == 0 ? ThemeMode.light : ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
