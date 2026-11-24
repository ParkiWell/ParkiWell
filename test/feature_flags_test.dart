import 'package:flutter_test/flutter_test.dart';
import 'package:parkiwell/services/cloud_backend_service.dart';
import 'package:parkiwell/services/feature_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a flag that has never been fetched uses the caller fallback', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final FeatureFlags flags = FeatureFlags();
    await flags.load();

    expect(flags.isEnabled('motion_coach'), isTrue);
    expect(flags.isEnabled('motion_coach', fallback: false), isFalse);
  });

  test('loads the cached flag map from storage', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      FeatureFlags.storageKey: '{"motion_coach": false}',
    });
    final FeatureFlags flags = FeatureFlags();
    await flags.load();

    expect(flags.isEnabled(FeatureFlags.motionCoachKey), isFalse);
  });

  test('a failed refresh keeps the last cached values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      FeatureFlags.storageKey: '{"motion_coach": false}',
    });
    final FeatureFlags flags = FeatureFlags();
    // An uninitialized backend has no client, so fetchAppFlags returns
    // null — exactly the offline / backend-down shape.
    await flags.refresh(CloudBackendService());

    expect(flags.isEnabled(FeatureFlags.motionCoachKey), isFalse);
  });

  test('listeners see changes from storage and refresh exactly once', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      FeatureFlags.storageKey: '{"motion_coach": false}',
    });
    final flags = FeatureFlags();
    final changes = <bool>[];
    flags.addListener(
      () => changes.add(flags.isEnabled(FeatureFlags.motionCoachKey)),
    );

    await flags.load();
    await flags.refresh(_EnabledFlagsCloud());
    await flags.refresh(_EnabledFlagsCloud());

    expect(changes, [false, true]);
  });

  test('an unreadable cache falls back instead of crashing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      FeatureFlags.storageKey: 'not json at all',
    });
    final FeatureFlags flags = FeatureFlags();
    await flags.load();

    expect(flags.isEnabled(FeatureFlags.motionCoachKey), isTrue);
  });
}

class _EnabledFlagsCloud extends Fake implements CloudBackendService {
  @override
  Future<Map<String, bool>?> fetchAppFlags() async => {
    FeatureFlags.motionCoachKey: true,
  };
}
