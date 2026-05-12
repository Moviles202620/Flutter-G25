/// Generic LRU (Least Recently Used) cache backed by a LinkedHashMap.
///
/// On get(): moves the entry to the tail (most recently used).
/// On put(): evicts the head (least recently used) when at capacity.
class LruCache<K, V> {
  final int capacity;
  // Dart map literals use LinkedHashMap internally — insertion order preserved.
  final _map = <K, V>{};

  LruCache({required this.capacity});

  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    // Move to tail — most recently used
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) _map.remove(key);
    // Evict head — least recently used — when full
    if (_map.length >= capacity) _map.remove(_map.keys.first);
    _map[key] = value;
  }

  bool containsKey(K key) => _map.containsKey(key);

  void remove(K key) => _map.remove(key);

  void clear() => _map.clear();

  int get length => _map.length;
}
