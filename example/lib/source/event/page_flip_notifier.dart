import 'dart:async';
import 'package:flutter/foundation.dart';

import '../enums/flipping_state.dart';
import '../enums/book_orientation.dart';

/// Event data for page flip events
class PageFlipEvent {
  final int page;
  final String? direction;
  final BookOrientation? mode;

  const PageFlipEvent({
    required this.page,
    this.direction,
    this.mode,
  });
}

/// Event data for state change events
class StateChangeEvent {
  final FlippingState newState;
  final FlippingState? previousState;

  const StateChangeEvent({
    required this.newState,
    this.previousState,
  });
}

/// Event data for settings update events
class SettingsUpdateEvent {
  final dynamic settings;
  final BookOrientation? mode;

  const SettingsUpdateEvent({
    required this.settings,
    this.mode,
  });
}

/// Flutter-native event notifier for PageFlip events using ChangeNotifier
class PageFlipNotifier extends ChangeNotifier {
  // Current state values
  PageFlipEvent? _currentFlipEvent;
  StateChangeEvent? _currentStateEvent;
  SettingsUpdateEvent? _currentSettingsEvent;
  bool _animationCompleted = false;
  bool _cleared = false;

  // Getters for current event data
  PageFlipEvent? get currentFlipEvent => _currentFlipEvent;
  StateChangeEvent? get currentStateEvent => _currentStateEvent;
  SettingsUpdateEvent? get currentSettingsEvent => _currentSettingsEvent;
  bool get animationCompleted => _animationCompleted;
  bool get cleared => _cleared;

  /// Notify about a page flip event
  void notifyFlip({
    required int page,
    String? direction,
    BookOrientation? mode,
  }) {
    _currentFlipEvent = PageFlipEvent(
      page: page,
      direction: direction,
      mode: mode,
    );
    notifyListeners();
  }

  /// Notify about a state change
  void notifyStateChange({
    required FlippingState newState,
    FlippingState? previousState,
  }) {
    _currentStateEvent = StateChangeEvent(
      newState: newState,
      previousState: previousState,
    );
    notifyListeners();
  }

  /// Notify about settings update
  void notifySettingsUpdate({
    required dynamic settings,
    BookOrientation? mode,
  }) {
    _currentSettingsEvent = SettingsUpdateEvent(
      settings: settings,
      mode: mode,
    );
    notifyListeners();
  }

  /// Notify about animation completion
  void notifyAnimationComplete() {
    _animationCompleted = true;
    notifyListeners();
    // Reset the flag after notifying
    _animationCompleted = false;
  }

  /// Notify about clear event
  void notifyClear() {
    _cleared = true;
    notifyListeners();
    // Reset the flag after notifying
    _cleared = false;
  }

  /// Reset all event states
  void reset() {
    _currentFlipEvent = null;
    _currentStateEvent = null;
    _currentSettingsEvent = null;
    _animationCompleted = false;
    _cleared = false;
  }
}

/// Stream-based event notifier for advanced use cases
class PageFlipStreamNotifier {
  // Private stream controllers
  final _flipController = StreamController<PageFlipEvent>.broadcast();
  final _stateController = StreamController<StateChangeEvent>.broadcast();
  final _settingsController = StreamController<SettingsUpdateEvent>.broadcast();
  final _animationController = StreamController<void>.broadcast();
  final _clearController = StreamController<void>.broadcast();

  // Public streams
  Stream<PageFlipEvent> get onFlip => _flipController.stream;
  Stream<StateChangeEvent> get onStateChange => _stateController.stream;
  Stream<SettingsUpdateEvent> get onSettingsUpdate => _settingsController.stream;
  Stream<void> get onAnimationComplete => _animationController.stream;
  Stream<void> get onClear => _clearController.stream;

  /// Notify about a page flip event
  void notifyFlip({
    required int page,
    String? direction,
    BookOrientation? mode,
  }) {
    _flipController.add(PageFlipEvent(
      page: page,
      direction: direction,
      mode: mode,
    ));
  }

  /// Notify about a state change
  void notifyStateChange({
    required FlippingState newState,
    FlippingState? previousState,
  }) {
    _stateController.add(StateChangeEvent(
      newState: newState,
      previousState: previousState,
    ));
  }

  /// Notify about settings update
  void notifySettingsUpdate({
    required dynamic settings,
    BookOrientation? mode,
  }) {
    _settingsController.add(SettingsUpdateEvent(
      settings: settings,
      mode: mode,
    ));
  }

  /// Notify about animation completion
  void notifyAnimationComplete() {
    _animationController.add(null);
  }

  /// Notify about clear event
  void notifyClear() {
    _clearController.add(null);
  }

  /// Dispose all stream controllers
  void dispose() {
    _flipController.close();
    _stateController.close();
    _settingsController.close();
    _animationController.close();
    _clearController.close();
  }
}
