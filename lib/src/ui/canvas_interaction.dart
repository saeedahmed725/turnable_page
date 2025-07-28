import 'dart:ui' show Offset;
import '../model/point.dart';
import '../model/swipe_data.dart';
import '../page/page_flip.dart';

/// Abstract UI Class, represents work with Flutter widgets
abstract class CanvasInteraction {
  late PageFlip app;
  double swipeDistance = 0.0;
  SwipeData? touchPoint;
  final int swipeTimeout = 250;

  /// Constructor
  CanvasInteraction(this.app);

  /// Update the PageFlip instance
  void updateApp(PageFlip app);

  /// Convert global coordinates to relative book coordinates
  Point getMousePos(double x, double y);

  /// Check if the target is valid for interaction
  bool checkTarget(dynamic target);

  /// Handle mouse/touch down event
  void onMouseDown(Point pos);

  /// Handle touch start event
  void onTouchStart(Point pos);

  /// Handle mouse/touch up event
  void onMouseUp(Point pos);

  /// Handle mouse/touch move event
  void onMouseMove(Point pos);

  /// Handle touch move event
  void onTouchMove(Point pos);

  /// Handle touch end event
  void onTouchEnd(Point pos);

  /// Handle mouse/touch down event from Flutter gesture
  void handleMouseDown(Offset position);

  /// Handle mouse/touch move event from Flutter gesture
  void handleMouseMove(Offset position);

  /// Handle mouse/touch up event from Flutter gesture
  void handleMouseUp(Offset position);

  /// Handle click event from Flutter gesture
  void handleClick(Offset position);
}
