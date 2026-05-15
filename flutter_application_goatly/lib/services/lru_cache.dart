import 'dart:collection';

/// Generic LRU (Least Recently Used) cache backed by a [LinkedHashMap].
///
/// ── Structure ───────────────────────────────────────────────────────────────
/// Uses Dart's [LinkedHashMap] which preserves INSERTION ORDER in O(1).
/// We treat the HEAD (oldest entry) as the LRU candidate and the TAIL
/// (newest entry) as the MRU (most recently used) entry.
///
/// ── Parameters ──────────────────────────────────────────────────────────────
/// [capacity] — maximum number of entries allowed in memory at once.
///   • CacheService uses capacity: 10 because the app has ≤ 10 analytics
///     endpoints (BQ2, BQ3, BQ7, BQ9, BQ10, insights, top-applicants, …).
///     Setting it higher would waste RAM; lower would cause too many evictions.
///   • Each entry is a `Map<String, dynamic>` payload (~1–5 KB JSON).
///     10 entries × 5 KB = ~50 KB max RAM — negligible on any modern device.
///
/// ── Access pattern ──────────────────────────────────────────────────────────
/// get(key):
///   • Miss → returns null (caller falls back to disk/network).
///   • Hit  → removes the entry and re-inserts it at the TAIL (promotes it
///             to MRU so it is the LAST one to be evicted).
///
/// put(key, value):
///   • If the key already exists, remove it first (re-order on update).
///   • If at capacity, evict the HEAD (oldest / LRU entry) before inserting.
///   • Insert new entry at the TAIL (MRU position).
///
/// ── Why LRU here? ───────────────────────────────────────────────────────────
/// Analytics payloads are large and expensive to fetch. The LRU policy keeps
/// the most-recently-visited tabs in memory, which matches real navigation
/// patterns: users revisit recent tabs far more than old ones. When the
/// capacity is full, the tab the user opened least recently is evicted —
/// it will be reloaded from the disk (SharedPreferences) on next access,
/// still much faster than a network round-trip.
class LruCache<K, V> {
  /// Maximum number of entries held in memory simultaneously.
  final int capacity;

  // LinkedHashMap preserves insertion order in O(1) — head = LRU, tail = MRU.
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  LruCache({required this.capacity});

  /// Returns the value for [key], or null if not cached.
  /// On hit, promotes the entry to MRU (tail) so it is evicted last.
  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    // Remove then re-insert → moves entry to tail (MRU position).
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  /// Stores [key] → [value].
  /// If already at [capacity], evicts the LRU entry (head) first.
  void put(K key, V value) {
    if (_map.containsKey(key)) _map.remove(key); // remove to re-order
    if (_map.length >= capacity) _map.remove(_map.keys.first); // evict LRU head
    _map[key] = value; // insert at tail (MRU)
  }

  bool containsKey(K key) => _map.containsKey(key);

  void remove(K key) => _map.remove(key);

  void clear() => _map.clear();

  /// Current number of entries in the cache (≤ [capacity]).
  int get length => _map.length;
}
