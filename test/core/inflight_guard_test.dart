import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/performance/inflight_guard.dart';

void main() {
  test('InflightGuard coalesces concurrent calls', () async {
    final guard = InflightGuard();
    var runs = 0;

    Future<int> task() async {
      runs++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return runs;
    }

    final a = guard.run('k', task);
    final b = guard.run('k', task);
    final results = await Future.wait([a, b]);

    expect(runs, 1);
    expect(results, [1, 1]);
  });
}
