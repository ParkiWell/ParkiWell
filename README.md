# Levio

A comprehensive health management application for individuals with Parkinson's disease. Levio provides tools to track symptoms, manage medications, and access guided speech therapy and physical exercises.

## Overview

Levio is designed to help Parkinson's patients take control of their health journey through intuitive tracking and therapeutic resources. The app features a modern, accessible interface optimized for ease of use.

## Features

### Symptom Tracking
- Log daily symptoms including tremors, rigidity, bradykinesia, and balance issues
- Rate symptom severity on a standardized scale
- Add notes and contextual information to each entry
- View historical data through interactive charts

### Medication Management
- Create and manage medication schedules
- Track dosage amounts and timing
- Review medication history for healthcare provider discussions

### Speech Therapy
- Audio-guided exercises to improve speech clarity and volume
- Breathing techniques and vocal warm-ups
- Articulation and pronunciation practice
- Self-paced learning with progress tracking

### Physical Exercises
- Video-guided workouts designed for Parkinson's patients
- Balance and stability training
- Stretching and flexibility routines
- Seated exercise options
- Walking and gait improvement exercises
- Hand dexterity and fine motor skill activities

### Data Visualization
- Interactive charts showing symptom patterns over time
- Progress tracking for therapy exercises
- Exportable health reports

## Requirements

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio (for Android development)
- Xcode (for iOS development)
- Firebase project with Firestore enabled

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/levio.git
cd levio
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a Firebase project at console.firebase.google.com
   - Add Android and iOS apps to your Firebase project
   - Download `google-services.json` and place it in `android/app/`
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`

4. Run the application:
```bash
flutter run
```

## Building for Release

### Android

Generate a release keystore (first time only):
```bash
keytool -genkey -v -keystore ~/levio-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias levio
```

Configure signing by copying `android/key.properties.example` to `android/key.properties` and filling in your keystore details.

Build release APK:
```bash
flutter build apk --release
```

Build App Bundle for Google Play:
```bash
flutter build appbundle --release
```

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing with your Apple Developer account
3. Build for release:
```bash
flutter build ipa --release
```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── singleton.dart            # State management
├── routes.dart               # Navigation configuration
├── theme/
│   └── app_theme.dart        # Theme definitions
├── screens/
│   └── splash_screen.dart    # Splash screen
├── Main/
│   ├── editProfile.dart      # Onboarding and profile editing
│   ├── manage.dart           # Health management dashboard
│   ├── profile.dart          # User profile
│   └── recovery.dart         # Recovery and therapy hub
├── Manage/
│   ├── log.dart              # Symptom log list
│   ├── editLog.dart          # Symptom entry editor
│   ├── schedule.dart         # Medication schedule list
│   └── editSchedule.dart     # Medication entry editor
├── Recovery/
│   ├── speech.dart           # Speech therapy exercises
│   ├── speechAudio.dart      # Audio exercise player
│   ├── exercise.dart         # Physical exercise list
│   └── exerciseVideo.dart    # Video exercise player
├── widgets/
│   ├── modern_card.dart      # Card components
│   ├── modern_button.dart    # Button components
│   └── modern_input.dart     # Input components
├── Firebase/
│   └── firebase_cloud.dart   # Firebase integration
└── utils/
    └── haptic_utils.dart     # Haptic feedback utilities
```

## Technology Stack

- **Framework**: Flutter 3.x with Material Design 3
- **State Management**: ChangeNotifier with SharedPreferences for persistence
- **Backend**: Firebase Cloud Firestore
- **Charts**: fl_chart
- **Audio**: audioplayers
- **Video**: youtube_player_iframe
- **Typography**: Google Fonts (Inter)

## Configuration

### Environment Variables

The application requires the following configuration:

- Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`)
- Release signing configuration (`key.properties` for Android)

### Supported Platforms

- Android (API 21+)
- iOS (12.0+)

## Privacy

Levio takes user privacy seriously. Health data is stored securely using Firebase Cloud Firestore with appropriate security rules. User data is never shared with third parties or used for advertising purposes.

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for complete privacy policy.

## License

This software is proprietary. See [LICENSE](LICENSE) for terms and conditions.

## Support

For technical support or bug reports, please open an issue on GitHub.

## Disclaimer

Levio is intended for health tracking and educational purposes only. It is not a medical device and should not be used to diagnose, treat, cure, or prevent any disease. Always consult with a qualified healthcare provider before making changes to your treatment plan.
