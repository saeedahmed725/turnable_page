import 'flip_direction.dart';

/// Events emitted by [PageFlip] during page flipping and state changes.
enum PageFlipEvent {
  /// Triggered once when the visible page changes (after a turn completes, or
  /// after a jump). The event data is the new page index as an `int`.
  flip,

  /// Triggered once for each page turn that is going to complete: when a
  /// programmatic turn starts, or when the user releases a drag that will
  /// finish the turn. Cancelled drags are not reported. The event data is
  /// the [FlipDirection] (`forward` = next page, also in right-to-left books).
  /// Use it to play a page-turn sound.
  turn,

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
