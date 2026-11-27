# Changelog

All notable changes to this project will be documented in this file.

## 2.2.0 - 2026-11-27
### ⚠️ Breaking changes
- **`PaperBoundaryDecoration` is removed**, with the `paperBoundaryDecoration` and `pagesBoundaryIsEnabled` parameters of `TurnablePage`, `TurnablePdf` and `TurnableImages`. Delete these arguments. For the look of a real book, use `FlipSettings(showPageEdges: true)`, whose page stacks follow the reading position.

### ✨ Features
- **`TurnableImages`**: a book made of images (comics, manga, catalogs, photo albums), from `ImageProvider`s, URLs (`.network`) or assets (`.asset`). The images around the current page are loaded ahead, so a turn never shows an empty page.
- **`PageScrubber`**: a page slider that follows the book. Drag or tap to jump (or turn, with `animate`) to any page, with an optional page preview. Colors, sizes, thumb, label and preview can all be changed. It runs right to left in RTL books.
- **Hard covers** (`FlipSettings.hardCover`, or `hardPages` for every page): the sheet swings around the spine as a stiff board, in perspective, instead of bending.
- **Page edges** (`FlipSettings.showPageEdges`, `pageEdgeWidth`): thin stacks against the outer edges of the pages. In a two-page spread, the left one grows and the right one shrinks as the reader moves through the book, and they move with each turn. A single page is half of an open book, so it shows only the stack of pages left to read, on its outer edge (the left edge in right-to-left books).
- **Corner hints**: `peekOnOpen` folds the first page's corner once when the book appears, and `PageFlipController.peek()` does it on demand.
- **Glossy paper** (`FlipSettings.paperGloss`, 0 to 1): a soft light band on the curl, like magazine paper.
- **Auto-play**: `PageFlipController.startAutoPlay(interval:, loop:, stopOnTouch:)` and `stopAutoPlay()`, for slideshows and kiosks.
- `PageFlipController` is now a `ChangeNotifier`: `ListenableBuilder` and `AnimatedBuilder` rebuild on page changes.
- **PDF links**: links in a `TurnablePdf` are tappable (`enableLinks`, on by default). Links to a page turn to it, and `onLinkTap` receives every tapped link, to open web links.
- **Sharper zoomed PDFs**: with zoom on, PDF pages are rendered at up to 3x resolution so text stays sharp when zoomed in.
- **Reduce motion** (`FlipSettings.respectReducedMotion`, on by default): turns last at most 200 ms when the system asks for less animation.
- **Sound and haptics**: `onPageTurn` on `TurnablePage` and `TurnablePdf` is called once for each turn that will complete, with its `FlipDirection`, for a page-turn sound. `FlipSettings.hapticFeedback` adds a light vibration on each turn. The new `PageFlipEvent.turn` event carries the same information for controller listeners.
- **Keyboard navigation** (`FlipSettings.keyboardNavigation`, on by default): arrow keys, Page Up/Down, Space, Home and End turn pages once the book is tapped or clicked. Arrows follow the reading direction in right-to-left books.
- **Mouse wheel and trackpad navigation** (`FlipSettings.mouseWheelNavigation`, off by default): one page per wheel gesture. Scroll views inside a page keep their scrolling.
- **Screen readers** announce the current page ("Page 3 of 10") and can turn pages with the adjust gestures. Translate the text with `semanticsValueBuilder`.
- **Adaptive shadows for dark paper** (`FlipSettings.adaptiveShadows`, on by default): shadows are drawn up to 1.8x stronger on a dark `pageBackgroundColor`, where black shadows lose contrast.
- `FlipDirection` is now exported.

### 🐛 Fixes
- **In single-page mode, the spine shadow popped onto a page at the end of a back turn.** It now belongs to the incoming page, on its spine edge, and grows as the page lands, like in a two-page spread.
- **A drag that started in the middle of a page made the fold jump to the finger.** The fold now starts at the page edge and catches up with the finger smoothly as it moves.
- **`showPageCorners` had no effect**: a corner now folds slightly when the mouse comes near it, on desktop and web. The fold grows gently as the mouse gets closer (within `cornerHoverSize`, 64 px by default) and falls back when it leaves. Buttons, links and text fields on a corner never fold it and stay clickable, with taps and clicks.
- **A small corner fold showed a white band** across the page near the bottom corner.
- **Single-page mode painted blank paper** to the left of the page (it was hidden behind the book frame).

## 2.1.1 - 2026-11-27
### ✨ Features
- **`coverSideBuilder`** on `TurnablePage`: fill the empty sides next to the covers (with `showCover` in a two-page spread) with your own widgets, such as endpapers or a logo. `CoverSide.front` is the side left of the front cover, `CoverSide.back` the side right of a lone last page. The widgets are interactive and turn with the pages.

### 🐛 Fixes
- **With `showCover`, the empty side of the cover spread showed a copy of the page being turned** while turning back to the front cover (or forward to a lone last page), then turned blank when the turn ended. It now shows plain paper (or the `coverSideBuilder` widget) during the whole turn.
- **The spine shadow no longer pops onto the new page at the end of a turn** in a two-page spread. It now belongs to the turning sheet, on its spine edge, and grows as the sheet lands.

### 🔧 Changes
- **License updated to TPPL v1.1**: you may use the package, unmodified, in any app, commercial apps included. Modifying, copying, redistributing or selling the package itself still needs permission. See [LICENSE](https://github.com/saeedahmed725/turnable_page/blob/main/LICENSE).
- Supports `pdfrx` 3.x (`>=2.4.4 <4.0.0`).
- The package no longer imports `package:flutter/material.dart`, ahead of its deprecation.
- Homepage moved to the documentation website.

## 2.1.0 - 2026-11-27
### ✨ Features
- **`enableDoubleTapZoom`** on `TurnablePage` and `FlipSettings` (default `true`): set it to `false` to turn off double-tap zoom while keeping pinch-to-zoom, so double tap is free for your own gestures ([#13](https://github.com/saeedahmed725/turnable_page/issues/13)).
- **`flipOnTap`** on `FlipSettings` (default `true`): set it to `false` when pages have their own tappable content. Taps then always reach the page, corners included, and pages turn only by dragging or from the controller.
- **Documentation website** with a live playground: https://saeedahmed725.github.io/turnable_page/

### 🔧 Changes
- Requires Flutter 3.35 or later. `pdfrx` updated to `^2.4.4` ([#12](https://github.com/saeedahmed725/turnable_page/pull/12)).
- `TurnablePdf.initPDFLoaders()` now uses pdfrx's own initializer, which sets the cache directory and the asset loader on every platform, web included.

## 2.0.0 - 2026-11-21
### ⚠️ Breaking changes
- `FlipSettings.startPageIndex` is now an **initial value only** (like `PageController.initialPage`). Changing it after the book is shown no longer navigates; use `PageFlipController.jumpToPage` / `animateToPage`.
- `PageFlipEvent.flip` fires once per page change, **after** the turn completes, and its data is always the new page index as an `int`. It used to also fire at the start of `flipNext` / `flipPrev` / `flip` with a `Map`.
- `PageFlipController` no longer throws `LateInitializationError` before a view is attached: check the new `hasClients`. Until then getters return neutral values and navigation returns `false`. `addEventListener` / `removeEventListener` throw a `StateError`.
- Single-page back turns by drag now start at the spine and follow the finger's travel, so a short back drag is cancelled instead of turning the page.

### 🐛 Fixes
- **A short back drag no longer turns the page** (single-page mode). The previous page used to jump in at the touch point (e.g. 150px on touch), and its release progress started at 50%, so every back drag passed the completion threshold. The release decision now uses the share of the page actually revealed, and a cancelled back turn returns to the spine instead of animating off screen.
- **Old page flashing at the end of a turn**: the last frames of a completed turn produced zero-area clip polygons, which hid the incoming page so the old page showed for one frame. Degenerate frames are now dropped when the animation is built, the turn completes in the same tick as its final frame, and the painter never clips with a collapsed area. Applies to forward and backward turns, taps, drags and flings.
- **`onPageChanged` fires once, with the new page, when the turn completes**. It used to fire twice per turn, and `flipNext` / `flipPrev` / `flip` reported the old page when the animation started. `PageFlipEvent.flip` now always carries the new page index as an `int`.
- **`startPageIndex` is an initial value only** (like `PageController.initialPage`). The widget no longer mutates the caller's settings, and rebuilding with the original settings no longer jumps back to an old page.
- Turning pages in large books no longer rebuilds every page in the window: built pages are reused and only the page entering the window is built.
- Single-page flips use detached page copies, so pages keep no stale flip geometry.
- A turning page with no clip area no longer paints a full unclipped white sheet.
- Replacing the `controller` on a live widget now attaches the new controller.
- **Forward and back turns now look equally fast in single-page mode.** The edge of a back turn moves 1:1 with the corner, while forward turns only show the first half of the corner's path. Back turns get a bigger frame budget and `previousPage()` starts at the spine instead of off-screen. Completed forward turns use a gentler, near-linear curve, so the flap no longer shoots across the page in ~75 ms.
- **Releasing a small corner fold returns smoothly** at both the top and bottom corners. The sag arc is scaled to the travel distance (a short return used to make the fold grow before shrinking), the return lasts at least 30% of `flippingTime`, and the bottom corner no longer pops on the last frame. That pop came from `FlipCalculation` only recognising the top corner's resting point.
- **Blank page after `jumpToPage` right after the first frame**: a page-change report deferred to a post-frame callback (the initial `startPageIndex`) could run after a newer jump. It moved the page window back to the old page, so the visible page was empty and `onPageChanged` reported the old page. Superseded reports are now dropped.
- `PageFlipController.hasClients` tells whether a view is attached. Before that, getters return neutral values and navigation methods return `false` instead of throwing `LateInitializationError`. The controller detaches when its view is disposed.
- **The page no longer slips out of the finger while dragging.** The checks that decide whether a drag may start (vertical scroll vs page turn, allowed direction) ran on every move. Steering the held page up or down, or moving back past the start point, aborted the turn. They now apply only before the drag starts.
- **The grabbed spot stays under the finger** (new `FlipSettings.keepGrabOffset`, default `true`). The dragged corner keeps its vertical offset from the touch point instead of jumping to the finger. Mid-height grabs now curl naturally and follow the finger when steered. Set it to `false` for the old behaviour.
- The first drag release in a session no longer finishes instantly.
- The paper frame (`PaperBoundaryDecoration`) no longer overflows its parent: `TurnablePage` gives the book the space left after the frame. The animation clock used to count the whole drag as elapsed time.

### ✨ New options
- `TurnablePage.pageCacheExtent` / `TurnablePageView.pageCacheExtent` (default 4): pages kept built on **each** side of the current page for books with more than 20 pages. The window is now symmetric (it used to be -4/+5).
- `FlipSettings.directionFromDrag` (default `false`): in single-page mode, the drag direction decides forward or back instead of where the finger landed. RTL books are mirrored automatically.
- `FlipSettings.pageBackgroundColor` (default white): the paper color under pages and on the back of a turning page, for example for dark mode.
- `FlipSettings.pageBorderColor` (nullable): the 1px border around the back of a turning page and around blank filler pages. It used to be hard-coded light gray, which showed as a bright line along the curl on dark pages. When `null`, it is derived from `pageBackgroundColor`: 12% darker for light backgrounds (white still gives `0xFFE0E0E0`) and no border for dark backgrounds.

## 1.1.0 - 2026-09-14
### ✨ New Features & Unified API
- **Unified PageViewMode**: Unified single-page vs two-page spread controls into a single parameter `pageViewMode` (`single`, `double`, `auto`):
  - `PageViewMode.single`: Always single page (portrait) across all devices and screen sizes.
  - `PageViewMode.double`: Always two-page spread (landscape).
  - `PageViewMode.auto`: Automatically responsive—displays a single page on mobile (<600px) and two-page spread on wide screens (>=600px).
  - Maintained 100% backward compatibility for deprecated `usePortrait`.
- **Dynamic Spread Synchronization**: Fixed orientation transition in auto mode when resizing between mobile and desktop. Automatically re-assigns spreads with zero blank pages.

### 🎨 Realistic Page Curl Physics
- **Authentic Paper Backside**: In single-page mode forward flip, the curling flap renders as a realistic 3D paper backside with natural fold gradients, keeping active page content visible on the page body during drag.
- **Directional Drag Locking**: Boundary flip prevention to reject invalid drag gestures on the first and last spreads.

### 🐞 Bug Fixes & Stability
- **Auto Mode Transition**: Fixed issue where switching from single to double page mode left the left page blank/white with Page 1 on the right.
- **Widget & Engine Synchronization**: Added `didUpdateWidget` to `TurnablePageView` to ensure runtime setting and constraint changes propagate cleanly to the render tree.
- **Safe Render Access**: Added `renderNullable` and `hasRender` getters to `PageFlip` for safe null-aware access.

## 1.0.2 - 2026-09-13
### ✨ New Features
- **Configurable Center Shadow**: Added `showCenterShadow` to `FlipSettings` to toggle the spine crease shadow between pages on or off.
- **Independent Shadow Colors**: Added individual color settings in `FlipSettings` for every shadow:
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