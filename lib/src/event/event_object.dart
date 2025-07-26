/// Data type passed to the event handler
typedef DataType = dynamic;

/// Type of object in event handlers
class WidgetEvent {
  final DataType data;
  final dynamic object;

  const WidgetEvent({required this.data, required this.object});
}

typedef EventCallback = void Function(WidgetEvent e);

/// A class implementing a basic event model
abstract class EventObject {
  final Map<String, List<EventCallback>> _events = <String, List<EventCallback>>{};

  /// Add new event handler
  ///
  /// @param {String} eventName
  /// @param {EventCallback} callback
  EventObject on(String eventName, EventCallback callback) {
    if (!_events.containsKey(eventName)) {
      _events[eventName] = [callback];
    } else {
      _events[eventName]!.add(callback);
    }

    return this;
  }

  /// Removing all handlers from an event
  ///
  /// @param {String} event - Event name
  void off(String event) {
    _events.remove(event);
  }

  void trigger(String eventName, dynamic app, [DataType? data]) {
    if (!_events.containsKey(eventName)) return;

    for (final callback in _events[eventName]!) {
      callback(WidgetEvent(data: data, object: app));
    }
  }
}
