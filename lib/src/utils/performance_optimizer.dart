import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';

/// Performance optimization utilities for the PageFlip widget
class PageFlipPerformanceOptimizer {
  /// Image cache with LRU eviction
  static final Map<String, ui.Image> _imageCache = {};
  static final List<String> _cacheOrder = [];
  static const int _maxCacheSize = 20;
  
  /// Performance metrics
  static final List<double> _renderTimes = [];
  static final List<double> _flipTimes = [];
  
  /// Throttling for expensive operations
  static Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 100);

  /// Cache an image with LRU management
  static void cacheImage(String key, ui.Image image) {
    // Remove existing entry to update order
    if (_imageCache.containsKey(key)) {
      _cacheOrder.remove(key);
    } else if (_imageCache.length >= _maxCacheSize) {
      // Evict oldest image
      final oldestKey = _cacheOrder.removeAt(0);
      final oldImage = _imageCache.remove(oldestKey);
      oldImage?.dispose();
    }
    
    _imageCache[key] = image;
    _cacheOrder.add(key);
  }

  /// Get cached image
  static ui.Image? getCachedImage(String key) {
    final image = _imageCache[key];
    if (image != null) {
      // Move to end (most recently used)
      _cacheOrder.remove(key);
      _cacheOrder.add(key);
    }
    return image;
  }

  /// Clear image cache
  static void clearImageCache() {
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();
    _cacheOrder.clear();
  }

  /// Record render time for performance monitoring
  static void recordRenderTime(double milliseconds) {
    _renderTimes.add(milliseconds);
    if (_renderTimes.length > 100) {
      _renderTimes.removeAt(0); // Keep only recent measurements
    }
  }

  /// Record flip time for performance monitoring
  static void recordFlipTime(double milliseconds) {
    _flipTimes.add(milliseconds);
    if (_flipTimes.length > 50) {
      _flipTimes.removeAt(0);
    }
  }

  /// Get average render time
  static double get averageRenderTime {
    if (_renderTimes.isEmpty) return 0.0;
    return _renderTimes.reduce((a, b) => a + b) / _renderTimes.length;
  }

  /// Get average flip time
  static double get averageFlipTime {
    if (_flipTimes.isEmpty) return 0.0;
    return _flipTimes.reduce((a, b) => a + b) / _flipTimes.length;
  }

  /// Debounce expensive operations
  static void debounce(VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, callback);
  }

  /// Cancel debounce timer
  static void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'cacheSize': _imageCache.length,
      'maxCacheSize': _maxCacheSize,
      'averageRenderTime': averageRenderTime,
      'averageFlipTime': averageFlipTime,
      'totalRenderSamples': _renderTimes.length,
      'totalFlipSamples': _flipTimes.length,
    };
  }

  /// Optimize image for display
  static Future<ui.Image> optimizeImage(ui.Image source, {
    double? maxWidth,
    double? maxHeight,
    double pixelRatio = 1.0,
  }) async {
    // If image is already optimal size, return as-is
    final targetWidth = maxWidth ?? source.width.toDouble();
    final targetHeight = maxHeight ?? source.height.toDouble();
    
    if (source.width <= targetWidth * pixelRatio && 
        source.height <= targetHeight * pixelRatio) {
      return source;
    }

    // Create optimized version
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    
    final paint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;
    
    canvas.drawImageRect(
      source,
      ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, targetWidth * pixelRatio, targetHeight * pixelRatio),
      paint,
    );
    
    final picture = recorder.endRecording();
    return await picture.toImage(
      (targetWidth * pixelRatio).toInt(),
      (targetHeight * pixelRatio).toInt(),
    );
  }

  /// Memory usage estimation
  static int estimateImageMemoryUsage(ui.Image image) {
    // Estimate bytes per pixel (RGBA = 4 bytes)
    return image.width * image.height * 4;
  }

  /// Get total cache memory usage estimate
  static int get totalCacheMemoryUsage {
    return _imageCache.values
        .map(estimateImageMemoryUsage)
        .fold(0, (sum, usage) => sum + usage);
  }

  /// Check if memory usage is within reasonable limits
  static bool get isMemoryUsageHealthy {
    const maxMemoryMB = 100; // 100MB limit
    const bytesPerMB = 1024 * 1024;
    return totalCacheMemoryUsage < (maxMemoryMB * bytesPerMB);
  }

  /// Cleanup memory if usage is too high
  static void cleanupMemoryIfNeeded() {
    if (!isMemoryUsageHealthy) {
      // Remove oldest half of the cache
      final removeCount = _cacheOrder.length ~/ 2;
      for (int i = 0; i < removeCount; i++) {
        final keyToRemove = _cacheOrder.removeAt(0);
        final imageToRemove = _imageCache.remove(keyToRemove);
        imageToRemove?.dispose();
      }
    }
  }

  /// Dispose all resources
  static void dispose() {
    clearImageCache();
    cancelDebounce();
    _renderTimes.clear();
    _flipTimes.clear();
  }
}

/// Mixin for widgets that want to use performance optimization
mixin PageFlipPerformanceMixin {
  final Stopwatch _performanceStopwatch = Stopwatch();
  
  void startPerformanceTimer() {
    _performanceStopwatch.reset();
    _performanceStopwatch.start();
  }
  
  void stopPerformanceTimer(String operation) {
    if (_performanceStopwatch.isRunning) {
      final elapsed = _performanceStopwatch.elapsedMilliseconds.toDouble();
      _performanceStopwatch.stop();
      
      if (operation.contains('render')) {
        PageFlipPerformanceOptimizer.recordRenderTime(elapsed);
      } else if (operation.contains('flip')) {
        PageFlipPerformanceOptimizer.recordFlipTime(elapsed);
      }
    }
  }
  
  void disposePerformance() {
    if (_performanceStopwatch.isRunning) {
      _performanceStopwatch.stop();
    }
  }
}

/// Utility for creating optimized Flutter widgets for pages
class PageWidgetOptimizer {
  /// Create an optimized RepaintBoundary for page content
  static Widget createOptimizedPageWidget({
    required Widget child,
    required GlobalKey key,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        key: key,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: child,
        ),
      ),
    );
  }

  /// Create a cached image provider for better performance
  static Widget createCachedImageWidget({
    required ui.Image image,
    required BoxFit fit,
    double? width,
    double? height,
  }) {
    return CustomPaint(
      size: ui.Size(width ?? image.width.toDouble(), height ?? image.height.toDouble()),
      painter: _ImagePainter(image, fit),
    );
  }
}

/// Custom painter for efficient image rendering
class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;
  
  _ImagePainter(this.image, this.fit);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;

    final imageRect = ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final canvasRect = ui.Rect.fromLTWH(0, 0, size.width, size.height);
    
    final fittedRect = _applyBoxFit(fit, imageRect.size, canvasRect.size);
    
    canvas.drawImageRect(image, imageRect, fittedRect, paint);
  }

  ui.Rect _applyBoxFit(BoxFit fit, ui.Size inputSize, ui.Size outputSize) {
    switch (fit) {
      case BoxFit.contain:
        final scale = (outputSize.width / inputSize.width)
            .clamp(0.0, outputSize.height / inputSize.height);
        final scaledSize = inputSize * scale;
        final offsetX = (outputSize.width - scaledSize.width) / 2;
        final offsetY = (outputSize.height - scaledSize.height) / 2;
        return ui.Rect.fromLTWH(offsetX, offsetY, scaledSize.width, scaledSize.height);
      
      case BoxFit.cover:
        final scale = (outputSize.width / inputSize.width)
            .clamp(outputSize.height / inputSize.height, double.infinity);
        final scaledSize = inputSize * scale;
        final offsetX = (outputSize.width - scaledSize.width) / 2;
        final offsetY = (outputSize.height - scaledSize.height) / 2;
        return ui.Rect.fromLTWH(offsetX, offsetY, scaledSize.width, scaledSize.height);
      
      case BoxFit.fill:
      default:
        return ui.Rect.fromLTWH(0, 0, outputSize.width, outputSize.height);
    }
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.fit != fit;
  }
}
