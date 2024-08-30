package util;

using ludi.commons.extensions.All;

class MessagingCenter {
    private static var subscribers = new Map<String, Map<String, Dynamic -> Void>>();

    public static function subscribe(eventType: String, callback: Dynamic -> Void): String {
        if (!subscribers.exists(eventType)) {
            subscribers.set(eventType, new Map<String, Dynamic -> Void>());
        }
        var token = haxe.crypto.Md5.encode(eventType + Std.string(Math.random()));
        subscribers.get(eventType).set(token, callback);
        return token;
    }

    public static function unsubscribe(token: String): Void {
        for (eventType in subscribers.keys()) {
            var eventSubscribers = subscribers.get(eventType);
            if (eventSubscribers.exists(token)) {
                eventSubscribers.remove(token);
                if (eventSubscribers.mapLength() <= 0) {
                    subscribers.remove(eventType);
                }
                break;
            }
        }
    }

    public static function notify(eventType: String, data: Dynamic): Void {
        if (subscribers.exists(eventType)) {
            for (token in subscribers.get(eventType).keys()) {
                subscribers.get(eventType).get(token)(data);
            }
        }
    }
}