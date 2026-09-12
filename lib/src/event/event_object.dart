import '../enums/page_flip_event.dart';
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

  /// The event that was triggered.
  final PageFlipEvent event;

  /// Creates a [WidgetEvent] with the given [data], [object], and [event].
  const WidgetEvent({
    required this.data,
    required this.object,
    required this.event,
  });
}

/// Provides a basic event model for adding, removing, and triggering event handlers.
///
/// Extend this class to allow your objects to emit and listen for events.
abstract class EventObject {
  /// Internal map of events to their registered callbacks.
  final Map<PageFlipEvent, List<EventCallback>> _events =
      <PageFlipEvent, List<EventCallback>>{};

  /// Registers a new event handler for the given [event].
  ///
  /// Returns this object to allow method chaining.
  EventObject on(PageFlipEvent event, EventCallback callback) {
    if (!_events.containsKey(event)) {
      _events[event] = [callback];
    } else {
      _events[event]!.add(callback);
    }
    return this;
  }

  /// Removes handlers for the specified [event].
  /// If [callback] is provided, only that specific callback is removed.
  /// If [callback] is omitted, all handlers for [event] are removed.
  void off(PageFlipEvent event, [EventCallback? callback]) {
    if (callback == null) {
      _events.remove(event);
    } else {
      _events[event]?.remove(callback);
      if (_events[event]?.isEmpty ?? false) {
        _events.remove(event);
      }
    }
  }

  /// Triggers the [event], passing [app] as the source and optional [data].
  ///
  /// Calls all registered callbacks for the event.
  void trigger(PageFlipEvent event, dynamic app, [dynamic data]) {
    final callbacks = _events[event];
    if (callbacks == null || callbacks.isEmpty) return;
    // Iterate over a copy of the list so callbacks can safely call off() without ConcurrentModificationError
    for (final callback in List<EventCallback>.from(callbacks)) {
      callback(WidgetEvent(data: data, object: app, event: event));
    }
  }
}
