# Changelog

All notable changes to this project will be documented in this file.

## 1.0.2 - 2026-09-13
### ✨ New Features
- **Configurable Center Shadow**: Added `showCenterShadow` to [FlipSettings](file:///e:/flutter/packages/turnable_page/lib/src/flip/flip_settings.dart) to toggle the spine crease shadow between pages on or off.
- **Independent Shadow Colors**: Added individual color settings in [FlipSettings](file:///e:/flutter/packages/turnable_page/lib/src/flip/flip_settings.dart) for every shadow:
  - `centerShadowColor`: Spine/crease shadow between two-page spreads.
  - `outerShadowColor`: Shadow cast on the page beneath the turning page.
  - `innerShadowColor`: Shadow cast on the back/inside of the curled page.
  - `perimeterShadowColor`: Elevation shadow along the curling page perimeter.
  - `perimeterBorderColor`: Subtle hairline border line along the curling edge.
- **Pinch-to-Zoom Support**: Added `enableZoom`, `minScale`, and `maxScale` settings to `TurnablePage` and `FlipSettings`, with `InteractiveViewer` integration, automatic page-flip gesture suppression while zoomed in, double-tap zoom toggle, and programmatic `controller.resetZoom()`.
- **Pages-Only Minimal Mode**: Added `PaperBoundaryDecoration.none` to disable all outer paper decorations and padding for modern minimal readers.
- **PaperBoundaryDecoration Customization**: Added native `copyWith(...)` method, `PaperBoundaryDecoration.custom(...)` factory constructor for intuitive high-level customization, and implemented value equality (`operator ==` / `hashCode`).

### 🐞 Bug Fixes & Architecture Stability
- **Gesture Harmony & Vertical Scroll Conflict**: Resolved issue where vertical scrolling inside `SingleChildScrollView` or `ListView` was hijacked by raw pointer handlers curling page corners. Implemented directional gesture locking with priority for vertical scrolling over page flipping.
- **Dynamic Image Flip Performance (Issue #9)**: Isolated active pages in `RepaintBoundary` layers so the 60fps flip animation transforms cached GPU `PictureLayer`s with zero dropped frames or repaint stalls on network/dynamic images.
- **Virtual Windowing for 150+ Pages (Issue #6)**: Transitioned from eager full-book widget instantiation to a sliding window (`current - 2 .. current + 3`), keeping memory consumption flat for large books of any page count.
- **Compositing Layer Lifetime (Issue #5)**: Replaced raw `canvas.save()`/`restore()` with Flutter `PaintingContext` layer transforms (`pushTransform`, `pushClipPath`) and compositing checks, fixing native peer collected `nullptr` crashes when rendering `RepaintBoundary` or `CachedNetworkImage`.
- **Layout Constraints (Issue #4)**: Fixed blank rendering and layout issues when embedding `Stack` and `SingleChildScrollView` inside pages.

### 🚀 API & Developer Experience
- **Canonical Async Navigation (Issue #6)**: Unified `PageFlipController` navigation methods (`nextPage()`, `previousPage()`, `animateToPage()`, `jumpToPage()`) to return `Future<bool>` directly without code duplication.
- **Type-Safe Events**: Converted event handling from raw string identifiers to the `PageFlipEvent` enum.

## 1.0.1 - 2025-09-30
### ✨ New Features
- **FlipSettings Controls**: Added `hideLeftShadow` to individually disable the left page shadow in single-page mode.
- **Vertical Flip Mode**: Introduced `onlyVerticalPageFlip` to support vertical-only page flipping by clamping gestures to the bottom edge.

### 🐞 Bug Fixes
- **Page Navigation**: Fixed `nextPage`/`previousPage` not working after the first page by resetting navigation state with a fresh key and animation timing.
- **Animation Lifecycle**: Ensured flip animations restart correctly by initializing `startedAt` whenever a new flip begins.

### 🚀 Enhancements
- **Example App UX**: Revamped the example to load pages asynchronously, show a loading indicator, and expose floating navigation buttons once data arrives.

### 🧹 Chores
- **Tooling**: Added `.fvmrc` to pin the Flutter version used for development.

## 1.0.0 - 2025-08-17
### 🔄 MAJOR ARCHITECTURE OVERHAUL
**BREAKING CHANGES:**
- **Complete migration from CustomPainter to Flutter RenderBox system**
- **Replaced image-based page rendering with live widget rendering**
- **Implemented direct child widget interaction without conversion overhead**

### ✨ New Features
- **Smart Gesture Detection**: Automatic differentiation between drag (page flip) and tap (widget interaction)
- **TurnablePdf Widget**: Built‑in PDF page flip viewer (asset / network / file) with single & double page modes, shimmer loading, custom loading/error builders, spine effect, and interactive page rendering
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
- Core page-