/// Coalesces concurrent identical async work (e.g. duplicate API calls).
class InflightGuard {
  final Map<String, Future<Object?>> _inflight = {};

  Future<T> run<T>(String key, Future<T> Function() task) {
    final existing = _inflight[key];
    if (existing != null) {
      return existing.then((value) => value as T);
    }

    final future = task().then<Object?>((v) => v).whenComplete(() {
      _inflight.remove(key);
    });

    _inflight[key] = future;
    return future.then((value) => value as T);
  }

  void clear() => _inflight.clear();
}
