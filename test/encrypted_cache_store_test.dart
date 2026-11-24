import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiwell/services/encrypted_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('seal and open round-trips a payload', () async {
    final store = EncryptedCacheStore();
    const payload = '{"log":[["08:00, 1 July 2026","Tremor","3"]]}';

    final sealed = await store.seal(payload);
    expect(sealed, startsWith(EncryptedCacheStore.payloadPrefix));
    expect(sealed, isNot(contains('Tremor')));

    expect(await store.open(sealed), payload);
  });

  test('two stores share one keystore key', () async {
    const payload = 'shared-secret-data';
    final sealed = await EncryptedCacheStore().seal(payload);

    // A fresh instance (fresh in-memory key cache) must still decrypt.
    expect(await EncryptedCacheStore().open(sealed), payload);
  });

  test('concurrent first writes can both be opened after restart', () async {
    final first = EncryptedCacheStore();
    final second = EncryptedCacheStore();
    final sealed = await Future.wait(<Future<String>>[
      first.seal('first record'),
      second.seal('second record'),
    ]);
    final reopened = EncryptedCacheStore();

    expect(sealed, everyElement(startsWith(EncryptedCacheStore.payloadPrefix)));
    expect(await reopened.open(sealed[0]), 'first record');
    expect(await reopened.open(sealed[1]), 'second record');
  });

  test('destroying the key invalidates other previously used stores', () async {
    final first = EncryptedCacheStore();
    final second = EncryptedCacheStore();
    final sealed = await first.seal('previous account');
    expect(await second.open(sealed), 'previous account');

    await first.destroyKey();

    expect(await second.open(sealed), isNull);
    final replacement = await second.seal('next account');
    expect(await EncryptedCacheStore().open(replacement), 'next account');
  });

  test('legacy plaintext payloads pass through for migration', () async {
    final store = EncryptedCacheStore();
    const legacy = '{"name":"Alex"}';

    expect(await store.open(legacy), legacy);
  });

  test('tampered ciphertext returns null instead of garbage', () async {
    final store = EncryptedCacheStore();
    final sealed = await store.seal('sensitive');

    final tampered =
        sealed.substring(0, sealed.length - 4) +
        (sealed.endsWith('AAAA') ? 'BBBB' : 'AAAA');
    expect(await store.open(tampered), isNull);
  });

  test('large payloads round-trip through the isolate path', () async {
    final store = EncryptedCacheStore();
    final payload = '{"log":"${'x' * 64 * 1024}"}';

    final sealed = await store.seal(payload);
    expect(sealed, startsWith(EncryptedCacheStore.payloadPrefix));
    expect(await store.open(sealed), payload);
  });

  test('sealed payloads differ between calls (fresh nonce)', () async {
    final store = EncryptedCacheStore();
    final first = await store.seal('same-input');
    final second = await store.seal('same-input');

    expect(first, isNot(second));
  });
}
