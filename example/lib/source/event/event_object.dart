import '../page/page_flip.dart';

/// Signature for event callback functions.
typedef EventCallback = void Function(WidgetEvent e);

/// An event object containing the event data and the source object.
///
/// Used in event callbacks to provide context and payload.
class WidgetEvent {
  /// The data associated with the event.
  final dynamic data;

  /// The object that triggered the event.
  final PageFlip object;

  /// Creates a [WidgetEvent] with the given [data] and [object].
  const WidgetEvent({required this.data, required this.object});
}

/// Provides a basic event model for adding, removing, and triggering event handlers.
///
/// Extend this class to allow your objects to emit and listen for events.
abstract class EventObject {
  /// Internal map of event names to their registered callbacks.
  final Map<String, List<EventCallback>> _events =
      <String, List<EventCallback>>{};

  /// Registers a new event handler for the given [eventName].
  ///
  /// Returns this object to allow method chaining.
  EventObject on(String eventName, EventCallback callback) {
    if (!_events.containsKey(eventName)) {
      _events[eventName] = [callback];
    } else {
      _events[eventName]!.add(callback);
    }
    return this;
  }

  /// Removes all handlers for the specified [event].
  void off(String event) {
    _events.remove(event);
  }

  /// Triggers the event named [eventName], passing [app] as the source and optional [data].
  ///
  /// Calls all registered callbacks for the event.
  void trigger(String eventName, dynamic app, [dynamic data]) {
    if (!_events.containsKey(eventName)) return;
    for (final callback in _events[eventName]!) {
      callback(WidgetEvent(data: data, object: app));
    }
  }
}
