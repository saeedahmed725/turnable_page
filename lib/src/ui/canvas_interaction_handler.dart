import 'package:flutter/material.dart';
import '../model/point.dart';
import '../page/page_flip.dart';
import '../enums/flip_corner.dart';
import '../enums/flipping_state.dart';
import '../model/swipe_data.dart';
import 'canvas_interaction.dart';

/// UI for canvas mode
class CanvasInteractionHandler extends CanvasInteraction {
  CanvasInteractionHandler(super.app);

  @override
  void updateApp(PageFlip app) {
    this.app = app;
    swipeDistance = app.getSettings.swipeDistance;
  }

  @override
  Point getMousePos(double x, double y) {
    return Point(x, y);
  }

  @override
  bool checkTarget(dynamic target) {
    if (!app.getSettings.clickEventForward) return true;
    return true;
  }

  @override
  void onMouseDown(Point pos) {
    if (checkTarget(null)) {
      app.startUserTouch(pos);
    }
  }

  @override
  void onTouchStart(Point pos) {
    if (checkTarget(null)) {
      touchPoint = SwipeData(
        point: pos,
        time: DateTime.now().millisecondsSinceEpoch,
      );

      Future.delayed(Duration(milliseconds: swipeTimeout), () {
        if (touchPoint != null) {
          app.startUserTouch(pos);
        }
      });
    }
  }

  @override
  void onMouseUp(Point pos) {
    app.userStop(pos);
  }

  @override
  void onMouseMove(Point pos) {
    app.userMove(pos, false);
  }

  @override
  void onTouchMove(Point pos) {
    if (app.getSettings.mobileScrollSupport) {
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

  @override
  void onTouchEnd(Point pos) {
    bool isSwipe = false;

    if (touchPoint != null) {
      final dx = pos.x - touchPoint!.point.x;
      final distY = (pos.y - touchPoint!.point.y).abs();

      if (dx.abs() > swipeDistance &&
          distY < swipeDistance * 2 &&
          DateTime.now().millisecondsSinceEpoch - touchPoint!.time <
              swipeTimeout) {
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

  @override
  void handleMouseDown(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseDown(point);
  }

  @override
  void handleMouseMove(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseMove(point);
  }

  @override
  void handleMouseUp(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseUp(point);
  }

  @override
  void handleClick(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseDown(point);
    onMouseUp(point);
  }
}
