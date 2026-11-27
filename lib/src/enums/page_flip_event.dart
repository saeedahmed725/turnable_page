/// Events emitted by [PageFlip] during page flipping and state changes.
enum PageFlipEvent {
  /// Triggered once when the visible page changes (after a turn completes, or
  /// after a jump). The event data is the new page index as an `int`.
  flip,

  /// Triggered when the flipping state changes (e.g. read, userFold, flipping, foldCorner).
  changeState,

  /// Triggered when orientation changes (portrait vs landscape).
  changeOrientation,

  /// Triggered when flip settings are updated.
  updateSettings,

  /// Triggered when pages are cleared.
  clear,

  /// Triggered when a flip animation completes.
  animationComplete,
}
