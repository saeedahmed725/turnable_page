import 'package:flutter/material.dart';
import 'dart:math';
import 'basic_types.dart';
import 'settings.dart';
import 'event/event_object.dart';
import 'render/render.dart';
import 'collection/page_collection.dart';
import 'collection/widget_page_collection.dart';
import 'flip/flip_enums.dart';
import 'flip/flip.dart';
import 'page/page.dart';
import 'dart:ui' as dart;

/// Class representing a main PageFlip object
class PageFlip extends EventObject {
  Point? mousePosition;
  bool isUserTouch = false;
  bool isUserMove = false;

  late final FlipSetting setting;
  late final Widget rootWidget; // Root Flutter Widget

  PageCollection? pages;
  Flip? flipController; // Flip controller
  Render? render;

  dynamic ui; // UI - will be defined later

  /// Create a new PageFlip instance
  ///
  /// @param {Widget} rootWidget - Root Flutter Widget
  /// @param {Map<String, dynamic>} setting - Configuration object
  PageFlip(this.rootWidget, Map<String, dynamic> setting) : super() {
    this.setting = Settings().getSettings(setting);
  }

  /// Create a new PageFlip instance with FlipSetting object
  ///
  /// @param {Widget} rootWidget - Root Flutter Widget
  /// @param {FlipSetting} setting - Configuration object
  PageFlip.withSettings(this.rootWidget, this.setting) : super();

  /// Destructor. Remove a root widget and all event handlers
  void destroy() {
    ui?.destroy();
    // In Flutter, widget disposal is handled by the framework
  }

  /// Update the render area. Re-show current page.
  void update() {
    render?.update();
    pages?.show();
  }

  /// Load pages from Flutter widgets
  ///
  /// @param {List<Widget>} items - List of page widgets
  void loadFromWidgets(List<dart.Image> images) {
    if (render == null) {
      throw Exception('Render must be initialized before loading widgets');
    }

    // Initialize flip controller
    flipController = Flip(render!, this);



    // Create simple widget page collection
    pages = WidgetPageCollection(this, render!, images);
    pages!.load();

    // Start rendering
    render!.start();

    // Show initial page
    pages!.show(setting.startPage);

    Future.delayed(const Duration(milliseconds: 1), () {
      ui?.update();
      trigger('init', this, {
        'page': setting.startPage,
        'mode': render!.getOrientation(),
      });
    });
  }



  /// Update pages from Flutter widgets
  ///
  /// @param {List<Widget>} items - List of page widgets
  void updateFromWidgets(List<dart.Image> images) {
    if (pages != null && render != null) {
      final current = pages!.getCurrentPageIndex();
      
      // Destroy current pages
      pages!.destroy();
      

      
      // Create new widget page collection
      pages = WidgetPageCollection(this, render!, images);
      pages!.load();
      
      // Reload render
      render!.reload();
      
      // Show current page (or first page if current is out of bounds)
      final pageToShow = current < images.length ? current : 0;
      pages!.show(pageToShow);
      
      trigger('update', this, {
        'page': pageToShow,
        'mode': render!.getOrientation(),
      });
    }
  }

  /// Clear all pages
  void clear() {
    pages?.destroy();
    ui?.update();
    
    trigger('clear', this, {});
  }

  /// Turn to previous page
  void turnToPrevPage() {
    pages?.showPrev();
  }

  /// Turn to next page
  void turnToNextPage() {
    pages?.showNext();
  }

  /// Turn to specific page
  ///
  /// @param {int} page - Page index
  void turnToPage(int page) {
    pages?.show(page);
  }

  /// Show page by number with optional corner specification
  /// 
  /// @param {int} pageNum - Page number to show (0-based)
  /// @param {String} corner - Corner to flip from ('top' or 'bottom')
  void showPage(int pageNum, [String? corner]) {
    if (pages != null) {
      pages!.show(pageNum);
      
      trigger('flip', this, {
        'page': pageNum,
        'mode': render!.getOrientation(),
      });
    }
  }

  /// Flip next page with animation
  ///
  /// @param {FlipCorner} corner - Corner to flip from
  void flipNext([FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;
    
    final currentIndex = getCurrentPageIndex();
    final totalPages = getPageCount();
    
    if (currentIndex < totalPages - 1) {
      // Use flip controller for animation if available
      if (flipController != null) {
        flipController!.flipNext(corner);
      } else {
        turnToNextPage();
      }
      
      trigger('flip', this, {
        'page': currentIndex + 1,
        'direction': 'next',
      });
    }
  }

  /// Flip previous page with animation
  ///
  /// @param {FlipCorner} corner - Corner to flip from
  void flipPrev([FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;
    
    final currentIndex = getCurrentPageIndex();
    
    if (currentIndex > 0) {
      // Use flip controller for animation if available
      if (flipController != null) {
        flipController!.flipPrev(corner);
      } else {
        turnToPrevPage();
      }
      
      trigger('flip', this, {
        'page': currentIndex - 1,
        'direction': 'prev',
      });
    }
  }

  /// Flip to specific page with animation
  ///
  /// @param {int} page - Page index
  /// @param {FlipCorner} corner - Corner to flip from
  void flip(int page, [FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;
    
    final totalPages = getPageCount();
    
    if (page >= 0 && page < totalPages) {
      final currentIndex = getCurrentPageIndex();
      
      // Use flip controller for animation if available
      if (flipController != null) {
        flipController!.flipToPage(page, corner);
      } else {
        turnToPage(page);
      }
      
      trigger('flip', this, {
        'page': page,
        'direction': page > currentIndex ? 'next' : 'prev',
      });
    }
  }

  /// Update flipping state
  ///
  /// @param {FlippingState} newState - New flipping state
  void updateState(FlippingState newState) {
    trigger('changeState', this, newState);
  }

  /// Update current page index
  ///
  /// @param {int} newPage - New page index
  void updatePageIndex(int newPage) {
    trigger('flip', this, newPage);
  }

  /// Update orientation
  ///
  /// @param {BookOrientation} newOrientation - New orientation
  void updateOrientation(BookOrientation newOrientation) {
    // Update UI orientation style if available
    ui?.setOrientationStyle(newOrientation);
    update();
    trigger('changeOrientation', this, newOrientation);
  }

  /// Get total page count
  int getPageCount() {
    return pages?.getPageCount() ?? 0;
  }

  /// Get current page index
  int getCurrentPageIndex() {
    return pages?.getCurrentPageIndex() ?? 0;
  }

  /// Get page by index
  ///
  /// @param {int} pageIndex - Page index
  BookPage? getPage(int pageIndex) {
    return pages?.getPage(pageIndex);
  }

  /// Get render object
  Render? getRender() {
    return render;
  }

  /// Get flip controller
  dynamic getFlipController() {
    return flipController;
  }

  /// Get current orientation
  BookOrientation? getOrientation() {
    return render?.getOrientation();
  }

  /// Get bounds rectangle
  PageRect? getBoundsRect() {
    return render?.getRect();
  }

  /// Get settings
  FlipSetting getSettings() {
    return setting;
  }

  /// Get UI object
  dynamic getUI() {
    if (ui == null) {
      throw Exception('UI has not been initialized yet');
    }
    return ui;
  }

  /// Get current flipping state
  FlippingState? getState() {
    return flipController?.getState();
  }

  /// Get page collection
  PageCollection? getPageCollection() {
    return pages;
  }

  /// Calculate distance between two points
  ///
  /// @param {Point} point1 - First point
  /// @param {Point} point2 - Second point
  /// @returns {double} Distance between points
  double _getDistanceBetweenPoints(Point point1, Point point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Start user touch interaction
  ///
  /// @param {Point} pos - Touch position
  void startUserTouch(Point pos) {
    isUserTouch = true;
    isUserMove = false;
    mousePosition = pos;

    // Initialize flip interaction if flip controller is available
    if (flipController != null) {
      flipController!.fold(pos);
    }
  }

  /// Handle user move
  ///
  /// @param {Point} pos - Current position
  /// @param {bool} isTouch - Whether this is a touch event
  void userMove(Point pos, bool isTouch) {
    if (isUserTouch) {
      if (mousePosition != null && _getDistanceBetweenPoints(mousePosition!, pos) > 5) {
        isUserMove = true;
        // Continue flip interaction
        if (flipController != null) {
          flipController!.fold(pos);
        }
      }
    }
  }

  /// Handle user stop interaction
  ///
  /// @param {Point} pos - End position
  /// @param {bool} isSwipe - Whether this was a swipe gesture
  void userStop(Point pos, [bool isSwipe = false]) {
    if (isUserTouch) {
      isUserTouch = false;

      if (!isSwipe) {
        if (!isUserMove) {
          // Single click/tap - trigger flip
          if (flipController != null) {
            flipController!.flip(pos);
          }
        } else {
          // End drag movement
          if (flipController != null) {
            flipController!.stopMove();
          }
        }
      }
    }
  }
}
