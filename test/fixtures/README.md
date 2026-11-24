# Motion Coach replay fixture

`motion-replays.v1.json.gz` contains the original ten exercises’ analytic
golden poses from `motion-coach-cv` and eight sequences of MediaPipe world
landmarks from the National Institute on Aging exercise demonstrations.
Source attribution for the demonstrations is in
[Demonstration video sources](../../assets/motion/videos/SOURCES.md).

Regenerate from a sibling `motion-coach-cv` checkout that has both its
`fixtures/golden/` and `data/captured-references/` inputs.

```sh
python3 scripts/build-motion-replays.py ../motion-coach-cv
flutter test test/motion_catalog_replay_test.dart
```

Each replay includes a SHA-256 digest of its source. World coordinates are
stored as integers in tenths of a millimetre, and visibility uses thousandths.
The recorded sequences are sampled at approximately 30 frames per second.
The test projects world coordinates into a fixed portrait viewport because
the recording files do not keep the original image-space landmarks. These
tests verify the app’s pose adapter, scoring, cue events, routine transitions,
and summary. Camera inference and device framing need separate tests.

## Expanded exercise references

Run `dart run scripts/build-expanded-motion-assets.dart` from the app root to
regenerate seven templates, their animated guides, two routines, and the
compressed replay fixture. The generator computes template features with the
same Dart engine that the app calls. These reference poses are analytic and
carry draft review status. The tests include opposite ankle and leg directions
and a whole-body turn that should earn no repetitions for an upper-body turn.

## Native mobile replay

Run these commands from the app root with a debug ParkiWell app installed on
the target. The native MediaPipe pipeline processes frames from the bundled
public-domain NIA forward-reach video. Use `adb -s` or `flutter test -d` to
select a device when multiple devices are available.

### Android

```bash
ffmpeg -y -i assets/motion/videos/seated_bilateral_forward_reach.demo.mp4 \
  -vf 'crop=384:480,fps=16' -pix_fmt yuv420p \
  -f rawvideo /tmp/parkiwell-forward-reach.yuv
adb shell run-as com.parkiwell.app.debug mkdir -p files
adb shell -T "run-as com.parkiwell.app.debug sh -c 'cat > files/motion-forward-reach.yuv'" \
  < /tmp/parkiwell-forward-reach.yuv
flutter test -d emulator-5554 --no-uninstall --dart-define=PARKIWELL_NATIVE_MOTION_REPLAY=true \
  integration_test/motion_native_replay_test.dart
```

### iOS simulator

```bash
sim_id=$(xcrun simctl getenv booted SIMULATOR_UDID)
sim_data=$(xcrun simctl get_app_container "$sim_id" com.parkiwell.app data)
mkdir -p "$sim_data/Library/Application Support"
ffmpeg -y -i assets/motion/videos/seated_bilateral_forward_reach.demo.mp4 \
  -vf 'crop=384:480,fps=16' -pix_fmt bgra -f rawvideo \
  "$sim_data/Library/Application Support/motion-forward-reach.bgra"
flutter test -d "$sim_id" --no-uninstall --dart-define=PARKIWELL_NATIVE_MOTION_REPLAY=true \
  integration_test/motion_native_replay_test.dart
```
