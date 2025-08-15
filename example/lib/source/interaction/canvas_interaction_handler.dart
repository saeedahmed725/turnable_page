import 'package:flutter/material.dart';

import '../enums/flip_corner.dart';
import '../enums/flipping_state.dart';
import '../model/point.dart';
import '../model/swipe_data.dart';
import '../page/page_flip.dart';
import 'canvas_interaction.dart';

/// UI for canvas mode
class CanvasInteractionHandler extends CanvasInteraction {
  late PageFlip app;
  double swipeDistance = 30.0;
  SwipeData? touchPoint;
  final int swipeTimeout = 250;

  CanvasInteractionHandler(this.app);

  @override
  void updateApp(PageFlip app) {
    this.app = app;
    swipeDistance = app.getSettings.swipeDistance;
  }

  @override
  Point getPos(Offset position) {
    return Point(position.dx, position.dy);
  }

  bool get _checkTarget => app.getSettings.clickEventForward;

  /// Handle mouse events
  @override
  void onMouseDown(Offset position) {
    app.startUserTouch(getPos(position));
  }

  @override
  void onMouseMove(Offset position) {
    if (_checkTarget) return;
    app.userMove(getPos(position), false);
  }

  @override
  void onMouseUp(Offset position) {
    app.userStop(getPos(position));
  }

  /// Handle touch events
  @override
  void handleOnPanStart(Offset position) {
    if (_checkTarget) return;

    touchPoint = SwipeData(
      point: getPos(position),
      time: DateTime.now().millisecondsSinceEpoch,
    );

    app.startUserTouch(getPos(position));
  }

  @override
  void handleOnPanUpdate(Offset position) {
    if (_checkTarget) return;
    if (app.getSettings.mobileScrollSupport) {
      if (touchPoint != null) {
        if ((touchPoint!.point.x - getPos(position).x).abs() > 10 ||
            app.getState() != FlippingState.read) {
          app.userMove(getPos(position), true);
        }
      }
    } else {
      app.userMove(getPos(position), true);
    }
  }

  @override
  void handleOnPanEnd(Offset position) {
    if (_checkTarget) return;
    bool isSwipe = false;

    if (touchPoint != null) {
      final dx = getPos(position).x - touchPoint!.point.x;
      final distY = (getPos(position).y - touchPoint!.point.y).abs();

      if (dx.abs() > swipeDistance &&
          distY < swipeDistance * 2 &&
          DateTime.now().millisecondsSinceEpoch - touchPoint!.time <
              swipeTimeout) {
        if (dx > 0) {
          final render = app.getRender();
          final halfHeight = render?.getRect().height != null ? render!.getRect().height / 2 : touchPoint!.point.y; // if render not ready, neutral comparison
          app.flipPrev(
            touchPoint!.point.y < halfHeight ? FlipCorner.top : FlipCorner.bottom,
          );
        } else {
          final render = app.getRender();
          final halfHeight = render?.getRect().height != null ? render!.getRect().height / 2 : touchPoint!.point.y;
          app.flipNext(
            touchPoint!.point.y < halfHeight ? FlipCorner.top : FlipCorner.bottom,
          );
        }
        isSwipe = true;
      }

      touchPoint = null;
    }

    app.userStop(getPos(position), isSwipe);
  }

  /// Handle click events
  @override
  void handleClick(Offset position) {
    if (!_checkTarget) return;
    onMouseDown(position);
    onMouseUp(position);
  }
}
