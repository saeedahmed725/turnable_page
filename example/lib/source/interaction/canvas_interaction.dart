import 'dart:ui' show Offset;

import '../model/point.dart';
import '../page/page_flip.dart';

/// Abstract UI Class, represents work with Flutter widgets
abstract class CanvasInteraction {
  /// Update the PageFlip instance
  void updateApp(PageFlip app);

  /// Convert global coordinates to relative book coordinates
  Point getPos(Offset position);

  /// Handle mouse/touch down event
  void onMouseDown(Offset position);

  /// Handle mouse/touch up event
  void onMouseUp(Offset position);

  /// Handle mouse/touch move event
  void onMouseMove(Offset position);

  /// Handle mouse/touch down event from Flutter gesture
  void handleOnPanStart(Offset position, void Function() onAction);

  /// Handle mouse/touch move event from Flutter gesture
  void handleOnPanUpdate(Offset position);

  /// Handle mouse/touch up event from Flutter gesture
  void handleOnPanEnd(Offset position);

  /// Handle click event from Flutter gesture
  void handleClick(Offset position);
}
