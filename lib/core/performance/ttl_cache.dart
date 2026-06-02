/// In-memory TTL cache for expensive local aggregations.
class TtlCache<T> {
  TtlCache({required Duration ttl}) : _ttl = ttl;

  final Duration _ttl;
  T? _value;
  DateTime? _storedAt;

  bool get isValid {
    if (_value == null || _storedAt == null) return false;
    return DateTime.now().difference(_storedAt!) < _ttl;
  }

  T? get value => isValid ? _value : null;

  void put(T value) {
    _value = value;
    _storedAt = DateTime.now();
  }

  void invalidate() {
    _value = null;
    _storedAt = null;
  }
}
