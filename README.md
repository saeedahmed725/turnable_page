# Turnable Page

[![pub package](https://img.shields.io/pub/v/turnable_page.svg)](https://pub.dev/packages/turnable_page)
[![likes](https://img.shields.io/pub/likes/turnable_page)](https://pub.dev/packages/turnable_page)
[![popularity](https://img.shields.io/pub/popularity/turnable_page)](https://pub.dev/packages/turnable_page)

A high-performance Flutter package providing a realistic 3D page-flipping effect for digital books, magazines, catalogs, PDFs, and interactive multi-page content.

Built from the ground up using Flutter's native `RenderBox` and compositing pipeline for smooth, 60fps hardware-accelerated animations.

---

## ✨ Features

- ✅ **Realistic 3D Physics & Curl**: Natural page-bending mechanics with dynamic lighting, authentic white paper backside, and layered drop shadows.
- ✅ **Unified `PageViewMode`**: Seamless single-page, two-page spread, or responsive `auto` mode that automatically adapts between mobile and desktop without blank pages.
- ✅ **Fully Interactive Pages**: Buttons, text fields, checkboxes, and clickable widgets inside pages work natively without any bitmap conversion overhead.
- ✅ **Gesture Harmony & Scroll Compatibility**: Intelligent gesture disambiguation—drag corners to flip pages, or scroll vertically inside `SingleChildScrollView` / `ListView` without conflict.
- ✅ **Built-in PDF Viewer (`TurnablePdf`)**: Turn real PDF documents (asset, network URL, or local file) with page-flip animation and raster caching.
- ✅ **Pinch-to-Zoom**: Built-in `InteractiveViewer` integration with double-tap zoom and programmatic zoom reset.
- ✅ **Customizable Shadows & Crease**: Full control over spine crease shadow, inner fold shadow, outer drop shadow, and perimeter elevation.
- ✅ **Paper Boundary Styles**: Choose between `modern`, `vintage`, `parchment`, borderless `none`, or define custom borders.
- ✅ **Full RTL Support**: Automatic or manual right-to-left reading direction (Arabic, Hebrew, etc.) with mirrored flipping mechanics.
- ✅ **Hardware Accelerated**: Zero `CustomPainter` bottlenecks; leverages Flutter `PaintingContext` and cached GPU layers.

---

## 📱 Demos

| Desktop Two-Page Spread | Mobile Single-Page Mode | Responsive Auto Adaptation |
|:---:|:---:|:---:|
| ![Desktop flipping](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/desktop-fliping.gif) | ![Mobile flipping](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/mobile-fliping.gif) | ![Responsiveness](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/responsiveness.gif) |

---

## 🚀 Getting Started

Add `turnable_page` to your `pubspec.yaml`:

```yaml
dependencies:
  turnable_page: ^1.1.0
```

Then install dependencies:

```bash
flutter pub get
```

---

## 📖 Usage Examples

### 1. Basic Interactive Book

```dart
import 'package:flutter/material.dart';
import 'package:turnable_page/turnable_page.dart';

class MyBookScreen extends StatelessWidget {
  const MyBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TurnablePage(
          pageCount: 6,
          pageViewMode: PageViewMode.auto, // Single on mobile (<600px), double on wide screens
          builder: (context, pageIndex, constraints) {
            return Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${pageIndex + 1}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Clicked on page ${pageIndex + 1}!')),
                        );
                      },
                      child: const Text('Interactive Button'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### 2. Page View Modes (`PageViewMode`)

`PageViewMode` provides a single, unified way to control layout across devices:

```dart
// 1. Always Single Page (portrait) regardless of screen width:
TurnablePage(
  pageViewMode: PageViewMode.single,
  pageCount: 10,
  builder: (context, index, constraints) => MyPage(index),
)

// 2. Always Two-Page Spread (landscape) regardless of screen width:
TurnablePage(
  pageViewMode: PageViewMode.double,
  pageCount: 10,
  builder: (context, index, constraints) => MyPage(index),
)

// 3. Responsive Auto Mode (recommended):
// Automatically shows 1 page on mobile (< 600px) and 2 pages on desktop/tablet (>= 600px).
TurnablePage(
  pageViewMode: PageViewMode.auto,
  pageCount: 10,
  builder: (context, index, constraints) => MyPage(index),
)
```

> **Note**: The legacy `usePortrait` parameter in `FlipSettings` is deprecated and automatically maps to `pageViewMode`.

---

### 3. Programmatic Control (`PageFlipController`)

Use `PageFlipController` to navigate programmatically with animated or instant transitions:

```dart
final controller = PageFlipController();

TurnablePage(
  controller: controller,
  pageCount: 8,
  builder: (context, index, constraints) => MyPage(index),
);

// Animated page navigation (returns Future<bool> completing when animation ends)
await controller.nextPage();
await controller.previousPage();
await controller.animateToPage(4);

// Instant navigation (without animation)
controller.jumpToPage(2);
controller.jumpToFirstPage();
controller.jumpToLastPage();

// State inspection
final current = controller.currentPageIndex;
final count = controller.pageCount;
final canGoForward = controller.hasNextPage;
final canGoBack = controller.hasPreviousPage;

// Pinch-to-zoom controls
if (controller.isZoomed) {
  controller.resetZoom();
}
```

---

### 4. Pinch-to-Zoom

Enable smooth pinch-to-zoom with gesture handling and double-tap zoom toggling:

```dart
TurnablePage(
  pageCount: 6,
  pageViewMode: PageViewMode.auto,
  enableZoom: true,
  minScale: 1.0,
  maxScale: 3.5,
  builder: (context, index, constraints) => MyPage(index),
)
```

When zoomed in, page flip gestures are automatically suspended so users can pan across detailed content. Double-tapping zooms back to normal scale.

---

### 5. Shadow Customization & Spine Crease

Fine-tune realistic 3D lighting, spine shadows, and page curl colors:

```dart
TurnablePage(
  pageCount: 8,
  settings: FlipSettings(
    drawShadow: true,
    showCenterShadow: true,               // Spine crease shadow in two-page spread
    centerShadowColor: Colors.black54,    // Spine shadow color
    outerShadowColor: Colors.black38,     // Shadow on the page beneath
    innerShadowColor: Colors.black26,     // Shadow inside the page fold
    perimeterShadowColor: Color(0x3D000000), // Elevation shadow along the page edge
    flippingTime: 650,                    // Flip duration in ms
    swipeDistance: 60,                    // Min drag distance to trigger flip
    cornerTriggerAreaSize: 0.2,           // Diagonal fraction for corner triggers
  ),
  builder: (context, index, constraints) => MyPage(index),
)
```

---

### 6. Paper Boundary Styles

Choose from pre-built boundary decorations or create your own:

```dart
// Vintage layered borders with warm margins
TurnablePage(
  paperBoundaryDecoration: PaperBoundaryDecoration.vintage,
  // ...
)

// Modern clean border with subtle elevation
TurnablePage(
  paperBoundaryDecoration: PaperBoundaryDecoration.modern,
  // ...
)

// Parchment textured aged paper
TurnablePage(
  paperBoundaryDecoration: PaperBoundaryDecoration.parchment,
  // ...
)

// Minimal / Borderless (pages take full allocated space without outer padding)
TurnablePage(
  paperBoundaryDecoration: PaperBoundaryDecoration.none,
  // ...
)

// Custom styling
TurnablePage(
  paperBoundaryDecoration: PaperBoundaryDecoration.custom(
    outerBorderColor: Colors.blueGrey,
    borderRadius: 8.0,
    elevationBlurRadius: 6.0,
  ),
  // ...
)
```

---

### 7. RTL Reading Direction

`TurnablePage` fully supports Right-to-Left (RTL) reading languages like Arabic, Hebrew, Urdu, and Persian:

```dart
TurnablePage(
  textDirection: TextDirection.rtl, // Or inherit automatically from Directionality
  pageCount: 10,
  builder: (context, index, constraints) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text('الصفحة ${index + 1}', style: const TextStyle(fontSize: 24)),
      ),
    );
  },
)
```

---

### 8. PDF Support (`TurnablePdf`)

Render PDF documents with full page-curl animations and multi-platform caching:

#### Initialization

Call once in `main()` before `runApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TurnablePdf.initPDFLoaders();
  runApp(const MyApp());
}
```

#### Network PDF

```dart
TurnablePdf.network(
  'https://example.com/magazine.pdf',
  pageViewMode: PageViewMode.auto,
  paperBoundaryDecoration: PaperBoundaryDecoration.modern,
)
```

#### Asset PDF

```dart
TurnablePdf.asset(
  'assets/documents/catalog.pdf',
  pageViewMode: PageViewMode.double,
)
```

#### File PDF

```dart
TurnablePdf.file(
  myPdfFile,
  pageViewMode: PageViewMode.single,
)
```

---

## ⚙️ Configuration Reference

### `TurnablePage` Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `builder` | `TurnableBuilder` | **Required** | Builds the widget content for each page index |
| `pageCount` | `int` | **Required** | Total number of pages |
| `pageViewMode` | `PageViewMode` | `PageViewMode.single` | `single`, `double`, or responsive `auto` |
| `controller` | `PageFlipController?` | `null` | Programmatic control and navigation |
| `onPageChanged` | `TurnablePageCallback?` | `null` | Callback fired on page changes with `(leftIndex, rightIndex)` |
| `textDirection` | `TextDirection?` | `null` | `ltr`, `rtl`, or inherits from ambient `Directionality` |
| `settings` | `FlipSettings?` | `FlipSettings()` | Physics, shadow, and gesture tuning |
| `paperBoundaryDecoration`| `PaperBoundaryDecoration` | `.vintage` | Visual style for book outer borders (`modern`, `vintage`, `none`, etc.) |
| `aspectRatio` | `double?` | `2/3` (single) / `4/3` (double) | Aspect ratio of the rendered book |
| `enableZoom` | `bool` | `false` | Enable pinch-to-zoom and double-tap zoom |
| `minScale` | `double` | `1.0` | Minimum zoom scale |
| `maxScale` | `double` | `3.0` | Maximum zoom scale |

---

### `FlipSettings` Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `startPageIndex` | `int` | `0` | Initial page index to display |
| `pageViewMode` | `PageViewMode?` | `PageViewMode.single` | Page display mode (`single`, `double`, `auto`) |
| `flippingTime` | `int` | `700` | Animation duration in milliseconds |
| `swipeDistance` | `double` | `100.0` | Swipe travel distance in px required to flip |
| `cornerTriggerAreaSize` | `double` | `0.1` | Fraction of page diagonal that triggers corner curls |
| `drawShadow` | `bool` | `true` | Toggle all shadow rendering |
| `showCenterShadow` | `bool` | `true` | Spine/crease shadow in two-page spread mode |
| `centerShadowColor` | `Color` | `Colors.black` | Color of the central spine shadow |
| `outerShadowColor` | `Color` | `Colors.black` | Color of the shadow cast on the page below |
| `innerShadowColor` | `Color` | `Colors.black` | Color of the curl fold shadow |
| `perimeterShadowColor` | `Color` | `Color(0x3D000000)` | Elevation shadow around curling sheet |
| `perimeterBorderColor` | `Color` | `Color(0x1F000000)` | Subtle hairline border on curled edge |
| `hideLeftShadow` | `bool` | `false` | Disable left-side shadow in single-page mode |
| `showCover` | `bool` | `false` | Treat first page as front cover and last page as back cover |
| `enableEasing` | `bool` | `true` | Cubic easing for realistic animations |
| `enableInertia` | `bool` | `true` | Complete swipe flips dynamically based on velocity |
| `onlyVerticalPageFlip` | `bool` | `false` | Restrict flip interaction to vertical drags |

---

## 🛠️ Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/saeedahmed725/turnable_page/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the Turnable Page Proprietary License (TPPL). See the [LICENSE](LICENSE) file for details.
