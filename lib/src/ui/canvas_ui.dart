import 'package:flutter/material.dart';
import 'ui.dart';
import '../page_flip.dart';
import '../settings.dart';
import '../basic_types.dart';
import '../render/canvas_render.dart';

/// UI for canvas mode
class CanvasUI extends UI {
  late final State widgetState;
  late Size canvasSize;

  CanvasUI(State inState, PageFlip app, FlipSetting setting) : super(Container(), app, setting) {
    widgetState = inState;
    canvasSize = Size(setting.width, setting.height);
    
    // Initialize the required UI elements for Flutter
    wrapper = SizedBox(
      width: setting.width,
      height: setting.height,
    );
    distElement = wrapper;
    
    setHandlers();
  }

  void resizeCanvas() {
    // In Flutter, resizing is handled by the framework
    canvasSize = Size(app.getSettings().width, app.getSettings().height);
  }

  /// Handle mouse/touch down event from Flutter gesture
  void handleMouseDown(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseDown(point);
    // Mark render as dirty for performance optimization
    if (app.getRender() is CanvasRender) {
      (app.getRender() as CanvasRender).markDirty();
    }
  }

  /// Handle mouse/touch move event from Flutter gesture
  void handleMouseMove(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseMove(point);
    // Mark render as dirty during movement
    if (app.getRender() is CanvasRender) {
      (app.getRender() as CanvasRender).markDirty();
    }
  }

  /// Handle mouse/touch up event from Flutter gesture
  void handleMouseUp(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseUp(point);
    // Mark render as dirty for final state
    if (app.getRender() is CanvasRender) {
      (app.getRender() as CanvasRender).markDirty();
    }
  }

  /// Handle click event from Flutter gesture
  void handleClick(Offset position) {
    final point = Point(position.dx, position.dy);
    onMouseDown(point);
    onMouseUp(point);
    // Mark render as dirty for click animation
    if (app.getRender() is CanvasRender) {
      (app.getRender() as CanvasRender).markDirty();
    }
  }

  @override
  void update() {
    resizeCanvas();
    app.getRender()?.update();
    
    // Trigger widget rebuild through callback or state management
    // The calling widget should handle this
  }
}
