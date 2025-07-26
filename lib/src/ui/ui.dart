import 'package:flutter/material.dart';
import '../basic_types.dart';
import '../settings.dart';
import '../page_flip.dart';
import '../flip/flip_enums.dart';
import '../render/render.dart';

class SwipeData {
  final Point point;
  final int time;

  const SwipeData({required this.point, required this.time});
}

/// UI Class, represents work with Flutter widgets
abstract class UI {
  late final Widget parentElement;
  late final PageFlip app;
  late final Widget wrapper;
  late Widget distElement;

  SwipeData? touchPoint;
  final int swipeTimeout = 250;
  late final double swipeDistance;

  /// Constructor
  ///
  /// @param {Widget} inBlock - Root Flutter Widget
  /// @param {PageFlip} app - PageFlip instance
  /// @param {FlipSetting} setting - Configuration object
  UI(Widget inBlock, this.app, FlipSetting setting) {
    parentElement = inBlock;
    swipeDistance = setting.swipeDistance;
    // Note: wrapper and distElement will be initialized in concrete implementations
  }

  /// Destructor. Remove all widgets and all event handlers
  void destroy() {
    if (app.getSettings().useMouseEvents) removeHandlers();
    // Widget cleanup is handled by Flutter framework
  }

  /// Updating child components when resizing
  void update();

  /// Get parent element for book
  Widget getDistElement() {
    return distElement;
  }

  /// Get wrapper element
  Widget getWrapper() {
    return wrapper;
  }

  /// Updates styles and sizes based on book orientation
  ///
  /// @param {BookOrientation} orientation - New book orientation
  void setOrientationStyle(BookOrientation orientation) {
    // In Flutter, we'll handle orientation changes through setState
    update();
  }

  void removeHandlers() {
    // Flutter gesture handling is different
  }

  void setHandlers() {
    // Flutter gesture handling is different
  }

  /// Convert global coordinates to relative book coordinates
  Point getMousePos(double x, double y) {
    // In Flutter, we'll get the RenderBox to calculate relative positions
    // This is a placeholder - actual implementation depends on widget context
    return Point(x, y);
  }

  bool checkTarget(dynamic target) {
    if (!app.getSettings().clickEventForward) return true;
    // In Flutter, we'll handle this differently with widget hierarchies
    return true;
  }

  // These methods will be handled by Flutter's GestureDetector
  void onMouseDown(Point pos) {
    if (checkTarget(null)) {
      app.startUserTouch(pos);
    }
  }

  void onTouchStart(Point pos) {
    if (checkTarget(null)) {
      touchPoint = SwipeData(
        point: pos,
        time: DateTime.now().millisecondsSinceEpoch,
      );

      // part of swipe detection
      Future.delayed(Duration(milliseconds: swipeTimeout), () {
        if (touchPoint != null) {
          app.startUserTouch(pos);
        }
      });
    }
  }

  void onMouseUp(Point pos) {
    app.userStop(pos);
  }

  void onMouseMove(Point pos) {
    app.userMove(pos, false);
  }

  void onTouchMove(Point pos) {
    if (app.getSettings().mobileScrollSupport) {
      if (touchPoint != null) {
        if ((touchPoint!.point.x - pos.x).abs() > 10 ||
            app.getState() != FlippingState.read) {
          app.userMove(pos, true);
        }
      }
    } else {
      app.userMove(pos, true);
    }
  }

  void onTouchEnd(Point pos) {
    bool isSwipe = false;

    // swipe detection
    if (touchPoint != null) {
      final dx = pos.x - touchPoint!.point.x;
      final distY = (pos.y - touchPoint!.point.y).abs();

      if (dx.abs() > swipeDistance &&
          distY < swipeDistance * 2 &&
          DateTime.now().millisecondsSinceEpoch - touchPoint!.time < swipeTimeout) {
        if (dx > 0) {
          app.flipPrev(
            touchPoint!.point.y < app.getRender()!.getRect().height / 2
                ? FlipCorner.top
                : FlipCorner.bottom,
          );
        } else {
          app.flipNext(
            touchPoint!.point.y < app.getRender()!.getRect().height / 2
                ? FlipCorner.top
                : FlipCorner.bottom,
          );
        }
        isSwipe = true;
      }

      touchPoint = null;
    }

    app.userStop(pos, isSwipe);
  }
}
