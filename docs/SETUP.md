# Run ParkiWell locally

You can build and run ParkiWell for Android or iOS using a public checkout.
The app starts in local-only mode with symptom tracking, medication schedules,
and Motion Coach.

## Requirements

- [Flutter 3.44.0](https://docs.flutter.dev/install), as pinned in
  [`.fvmrc`](../.fvmrc)
- Android Studio with the Android SDK and JDK 17 for Android development
- macOS with Xcode and CocoaPods for iOS development

From the repository root, check your toolchain and start the app.

```bash
flutter doctor
flutter pub get
flutter devices
flutter run
```

Flutter prompts you to select a device if more than one is available. Motion
Coach needs a front-facing camera for live practice. Most of the app can be
explored on a simulator or emulator.

To test sign-in, account sync, or community features, follow the
[optional Supabase setup](BACKEND_SETUP.md) using a project you control.
