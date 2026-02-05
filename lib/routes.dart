import 'package:levio/Manage/editLog.dart';
import 'package:levio/Manage/editSchedule.dart';
import 'package:levio/Manage/log.dart';
import 'package:levio/Manage/schedule.dart';
import 'package:levio/Recovery/exercise.dart';
import 'package:levio/Recovery/exerciseVideo.dart';
import 'package:levio/Recovery/games.dart';
import 'package:levio/Recovery/speech.dart';
import 'package:levio/Recovery/speechAudio.dart';
import 'package:levio/settings.dart';

// Named routes (excluding '/' since we use home parameter)
var namedRoutes = {
  '/editLogScreen': (context) => const EditLogScreen(),
  '/editScheduleScreen': (context) => const EditScheduleScreen(),
  '/logScreen': (context) => const LogScreen(),
  '/scheduleScreen': (context) => const ScheduleScreen(),
  '/exerciseScreen': (context) => const ExerciseScreen(),
  '/exerciseVideoScreen': (context) => const ExerciseVideo(),
  '/speechAudio': (context) => const SpeechAudio(),
  '/gamesScreen': (context) => const GamesScreen(),
  '/speechScreen': (context) => const SpeechScreen(),
  '/settingsScreen': (context) => const SettingsScreen()
};
