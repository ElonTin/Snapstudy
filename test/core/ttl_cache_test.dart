import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/performance/ttl_cache.dart';

void main() {
  test('TtlCache returns value within TTL', () async {
    final cache = TtlCache<String>(ttl: const Duration(milliseconds: 100));
    cache.put('hello');
    expect(cache.value, 'hello');
    expect(cache.isValid, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(cache.isValid, isFalse);
    expect(cache.value, isNull);
  });

  test('TtlCache invalidate clears value', () {
    final cache = TtlCache<int>(ttl: const Duration(minutes: 1));
    cache.put(42);
    cache.invalidate();
    expect(cache.value, isNull);
  });
}
