package util;

using ludi.commons.extensions.All;

class Caching {
    static var CACHE: Map<String, Dynamic> = new Map<String, Dynamic>();
    static var MAX_CACHE_SIZE: Int = 1000;

    public static function get(key: String): Dynamic {
        return CACHE.get(key);
    }

    public static function set(key: String, value: Dynamic): Void {
        if (CACHE.mapLength() >= MAX_CACHE_SIZE) {
            evictOldest();
        }
        CACHE.set(key, value);
    }

    public static function exists(key: String): Bool {
        return CACHE.exists(key);
    }

    public static function remove(key: String): Void {
        CACHE.remove(key);
    }

    private static function evictOldest(): Void {
        var oldestKey: String = null;
        for (key in CACHE.keys()) {
            oldestKey = key;
            break;
        }
        if (oldestKey != null) {
            CACHE.remove(oldestKey);
        }
    }

    public static function clear(): Void {
        CACHE = new Map<String, Dynamic>();
    }
}