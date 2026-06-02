import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';

void main() {
  test('Success fold returns value', () {
    const result = Success(42);
    expect(
      result.fold(onSuccess: (v) => v, onFailure: (_) => -1),
      42,
    );
  });

  test('Error fold returns failure', () {
    const result = Error<int>(ValidationFailure('bad'));
    expect(
      result.fold(onSuccess: (_) => 'ok', onFailure: (f) => f.message),
      'bad',
    );
  });

  test('flatMap short-circuits on Error', () async {
    const result = Error<int>(ValidationFailure('x'));
    final next = await result.flatMap((v) async => Success(v * 2));
    expect(next.isFailure, true);
  });

  test('map transforms Success', () {
    const result = Success(3);
    expect(result.map((v) => v + 1).valueOrNull, 4);
  });
}
