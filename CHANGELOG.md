# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0 - 2025-08-16
### 🔄 MAJOR ARCHITECTURE OVERHAUL
**BREAKING CHANGES:**
- **Complete migration from CustomPainter to Flutter RenderBox system**
- **Replaced image-based page rendering with live widget rendering**
- **Implemented direct child widget interaction without conversion overhead**

### ✨ New Features
- **Smart Gesture Detection**: Automatic differentiation between drag (page flip) and tap (widget interaction)
- **Interactive Widgets**: Buttons and other widgets within pages now work natively without any conversion
- **Enhanced Physics**: Added inertia, easing, and realistic page bending animations
- **Improved Performance**: Eliminated expensive widget-to-image conversion pipeline
- **Better Hit Testing**: Intelligent detection of interactive widgets vs page flip areas

### 🏗️ Technical Improvements
- **RenderTurnableBook**: Custom RenderBox with proper Flutter integration
- **Frame Scheduling**: Integrated with SchedulerBinding for smooth animations
- **Gesture System**: Complete rewrite of pointer event handling
- **Memory Optimization**: Direct widget rendering with cached clipping paths
- **Error Handling**: Fixed "Build scheduled during frame" issues

### 🎨 Enhanced Visual Effects
- **Native Shadow System**: Using Flutter's painting system for realistic shadows
- **Clipping Optimization**: Cached path generation for complex page shapes
- **Animation Quality**: Improved frame-based animation with configurable physics

### 📚 Developer Experience
- **Cleaner API**: Simplified configuration with automatic behavior
- **Better Documentation**: Comprehensive Arabic examples and guides
- **Edge Case Handling**: Improved stability and error recovery
- **Configuration Options**: Extensive customization for gesture detection and animation

### 🗑️ Removed
- Custom canvas interaction handlers
- Image conversion utilities
- Complex painter systems
- Manual widget tree management

## 0.0.1+1 - 2025-08-09
- Docs: Update README to use GitHub-hosted GIFs that render on pub.dev
- Chore: Add `.pubignore` to exclude large `videos/` from published package
- Docs: Minor copy updates

## 0.0.1 - 2025-08-09
- Initial release of Turnable Page package.
- Core page-flip widget, controller, settings, and example app.
