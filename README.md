# Turnable Page

A Flutter package that provides a realistic page-flipping effect for digital books, magazines, catalogs, and other multi-page content in Flutter applications.

## Features

✅ **Realistic Physics**: Advanced flip animations with proper physics and shadows  
✅ **Interactive Content**: Full support for interactive widgets (buttons, inputs, etc.) within pages  
✅ **Smart Gestures**: Automatic differentiation between drag (page flip) and tap (widget interaction)  
✅ **Touch Support**: Full touch and gesture support for mobile devices  
✅ **Multiple Orientations**: Automatic portrait/landscape orientation handling  
✅ **Widget Support**: Use any Flutter widget as page content with full interactivity  
✅ **Customizable**: Extensive configuration options for gestures and animations  
✅ **Performance**: Hardware-accelerated rendering using Flutter's native RenderBox system  
✅ **Events**: Rich event system for interaction handling  
✅ **Responsive**: Auto-sizing and responsive layout support  
✅ **Cross-Platform**: Supports Mobile, Web, and Windows  

> **NEW**: Widgets inside book pages are now fully interactive! The smart gesture system automatically detects when you're interacting with buttons or other widgets vs. when you want to flip pages.

## Demo (GIF)

Animated GIF previews below. To keep the published package small, demo GIFs are hosted on GitHub.

### Desktop flipping

![Desktop flipping](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/desktop-fliping.gif)

### Mobile flipping

![Mobile flipping](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/mobile-fliping.gif)

### Responsiveness

![Responsiveness](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/responsiveness.gif)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  turnable_page: ^1.0.0
```

Then run:
```bash
flutter pub get
```

## Basic Usage

### Simple Widget-Based Book

```dart
import 'package:flutter/material.dart';
import 'package:turnable_page/turnable_page.dart';

class MyBook extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 600,
          child: TurnablePage(
            pageCount: 6,
            pageBuilder: (index, constraints) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Text(
                    'Page ${index + 1}',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

### With Controller and Events

```dart
class BookWithController extends StatefulWidget {
  @override
  _BookWithControllerState createState() => _BookWithControllerState();
}

class _BookWithControllerState extends State<BookWithController> {
  late PageFlipController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageFlipController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${_currentPage + 1}'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _controller.hasPreviousPage 
              ? () => _controller.previousPage() 
              : null,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _controller.hasNextPage 
              ? () => _controller.nextPage() 
              : null,
          ),
        ],
      ),
      body: TurnablePage(
        controller: _controller,
        pageCount: 10,
        onPageChanged: (leftIndex, rightIndex) {
          setState(() {
            _currentPage = leftIndex;
          });
        },
        pageBuilder: (index, constraints) {
          return Container(
            color: Colors.primaries[index % Colors.primaries.length],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Page ${index + 1}',
                    style: TextStyle(fontSize: 32, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Icon(
                    Icons.book,
                    size: 64,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Advanced Configuration

```dart
TurnablePage(
  pageCount: 20,
  pageBuilder: pageBuilder,
  controller: controller,
  onPageChanged: onPageChanged,
  
  // Visual appearance
  pageViewMode: PageViewMode.single, // or PageViewMode.double
  pixelRatio: 3.0,
  aspectRatio: 2/3, // Custom aspect ratio
  autoResponseSize: true,
  paperBoundaryDecoration: PaperBoundaryDecoration.vintage,
  
  // Flip settings
  settings: FlipSettings(
    // Page positioning
    startPageIndex: 0,
    
    // Size configuration
    size: SizeType.fixed, // or SizeType.stretch
    width: 400.0,
    height: 600.0,
    
    // Visual effects
    drawShadow: true,
    maxShadowOpacity: 1.0,
    showPageCorners: true,
    
    // Animation
    flippingTime: 700, // milliseconds
    
    // Behavior
    usePortrait: true,
    showCover: false,
    mobileScrollSupport: true,
    clickEventForward: false,
    swipeDistance: 100.0,
    disableFlipByClick: false,
  ),
)
```

## Smart Gesture System

The package now features an intelligent gesture detection system that automatically differentiates between user intentions:

### 🎯 Automatic Behavior
- **Drag gestures** = Page flipping
- **Tap gestures** = Widget interaction (buttons, inputs, etc.)

### 🧠 How It Works
The system uses advanced hit testing to detect when you're interacting with interactive widgets:

```dart
TurnablePage(
  pageCount: 5,
  builder: (context, index, constraints) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Page ${index + 1}'),
          
          // This button will work normally - taps won't flip pages
          ElevatedButton(
            onPressed: () {
              print('Button pressed on page $index');
            },
            child: Text('Interactive Button'),
          ),
          
          // This text is non-interactive - taps will flip pages
          Text('Tap here to flip pages'),
        ],
      ),
    );
  },
  
  // Smart gestures enabled by default
  settings: FlipSettings(
    enableSmartGestures: true, // Default: true
    cornerTriggerAreaSize: 0.15, // Corner sensitivity (15% of diagonal)
    swipeDistance: 80.0, // Minimum drag distance for page flip
  ),
)
```

### ⚙️ Configuration Options

```dart
FlipSettings(
  // Enable/disable smart gesture detection
  enableSmartGestures: true,
  
  // Size of corner areas that trigger page flips on tap
  // 0.1 = 10% of page diagonal, 0.2 = 20%, etc.
  cornerTriggerAreaSize: 0.15,
  
  // Minimum distance to drag before triggering page flip
  swipeDistance: 80.0,
  
  // Disable tap-to-flip entirely (drag only)
  disableFlipByClick: false,
)
```

### 📱 Usage Tips
1. **For maximum interactivity**: Use `enableSmartGestures: true` (default)
2. **For page-flipping only**: Use `disableFlipByClick: true` to require dragging
3. **Adjust sensitivity**: Modify `cornerTriggerAreaSize` to change corner tap areas
4. **Fine-tune dragging**: Adjust `swipeDistance` for drag sensitivity

## API Reference

### TurnablePage Widget

The main widget for creating a page-flipping book interface.

#### Constructor

```dart
TurnablePage({
  Key? key,
  PageFlipController? controller,
  double? aspectRatio,
  required TurnableBuilder pageBuilder,
  required int pageCount,
  TurnablePageCallback? onPageChanged,
  PageViewMode pageViewMode = PageViewMode.single,
  double pixelRatio = 3.0,
  bool autoResponseSize = true,
  PaperBoundaryDecoration paperBoundaryDecoration = PaperBoundaryDecoration.vintage,
  FlipSettings? settings,
})
```

#### Parameters

- `controller` - Optional controller for programmatic page control
- `pageBuilder` - Builder function that creates widget content for each page
- `pageCount` - Total number of pages in the book
- `onPageChanged` - Callback fired when page changes
- `pageViewMode` - Display mode: single page or double page spread
- `pixelRatio` - Rendering pixel ratio for quality
- `autoResponseSize` - Whether to automatically adjust size to container
- `aspectRatio` - Custom aspect ratio for the book
- `paperBoundaryDecoration` - Visual style for page boundaries
- `settings` - Detailed flip behavior configuration

### PageFlipController

Controller class for programmatic page manipulation.

#### Methods

- `nextPage()` - Turn to the next page (without animation)
- `previousPage()` - Turn to the previous page (without animation)
- `goToPage(int pageIndex)` - Jump to a specific page (without animation)
- `flipNext([FlipCorner corner])` - Flip to next page with animation
- `flipPrev([FlipCorner corner])` - Flip to previous page with animation
- `flipToPage(int pageIndex, [FlipCorner corner])` - Flip to specific page with animation

#### Properties

- `currentPageIndex` - Get current page index (0-based)
- `pageCount` - Get total number of pages
- `hasNextPage` - Check if next page is available
- `hasPreviousPage` - Check if previous page is available
- `canFlipNext` - Check if can flip to next page
- `canFlipPrev` - Check if can flip to previous page

### FlipSettings Configuration

Configuration object for customizing flip behavior and appearance.

#### Constructor Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `startPageIndex` | `int` | `0` | Initial page to display (0-based index) |
| `size` | `SizeType` | `SizeType.fixed` | Size calculation: fixed dimensions or stretch to fit |
| `width` | `double` | `0` | Width of the book in pixels |
| `height` | `double` | `0` | Height of the book in pixels |
| `drawShadow` | `bool` | `true` | Whether to draw realistic shadow effects |
| `flippingTime` | `int` | `700` | Duration of flip animation in milliseconds |
| `usePortrait` | `bool` | `true` | Portrait mode (single page) vs landscape (two-page spread) |
| `maxShadowOpacity` | `double` | `1.0` | Maximum opacity for shadow effects (0.0 to 1.0) |
| `showCover` | `bool` | `false` | Whether the book has a front/back cover |
| `mobileScrollSupport` | `bool` | `true` | Enable touch scrolling on mobile devices |
| `clickEventForward` | `bool` | `false` | Whether click events propagate to parent widgets |
| `swipeDistance` | `double` | `100.0` | Minimum distance in pixels for swipe gesture |
| `showPageCorners` | `bool` | `true` | Show interactive corner highlighting on hover |
| `disableFlipByClick` | `bool` | `false` | Disable page flipping via click (drag only) |


#### PageViewMode
- `PageViewMode.single` - Single page view (portrait orientation)
- `PageViewMode.double` - Double page spread (landscape orientation)

#### SizeType
- `SizeType.fixed` - Fixed dimensions specified by width/height
- `SizeType.stretch` - Stretch to fit parent container

#### FlipCorner
- `FlipCorner.topLeft` - Flip from top-left corner
- `FlipCorner.topRight` - Flip from top-right corner  
- `FlipCorner.bottomLeft` - Flip from bottom-left corner
- `FlipCorner.bottomRight` - Flip from bottom-right corner

#### PaperBoundaryDecoration
- `PaperBoundaryDecoration.vintage` - Vintage paper styling
- `PaperBoundaryDecoration.modern` - Modern clean styling
- `PaperBoundaryDecoration.parchment` - Parchment-style textured paper with warm, aged tones

## Examples

Note: Image-based examples inside the book have been temporarily removed and will be added in a future update.

### Basic Book Reader with Navigation

```dart
class BookReader extends StatefulWidget {
  @override
  _BookReaderState createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  late PageFlipController _controller;
  int _currentPage = 0;
  
  final List<Color> _pageColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  
  @override
  void initState() {
    super.initState();
    _controller = PageFlipController();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Reader'),
        actions: [
          IconButton(
            icon: Icon(Icons.first_page),
            onPressed: () => _controller.goToPage(0),
          ),
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _controller.hasPreviousPage 
              ? () => _controller.flipPrev() 
              : null,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text('${_currentPage + 1} / ${_pageColors.length}'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _controller.hasNextPage 
              ? () => _controller.flipNext() 
              : null,
          ),
          IconButton(
            icon: Icon(Icons.last_page),
            onPressed: () => _controller.goToPage(_pageColors.length - 1),
          ),
        ],
      ),
      body: TurnablePage(
        controller: _controller,
        pageCount: _pageColors.length,
        onPageChanged: (leftIndex, rightIndex) {
          setState(() {
            _currentPage = leftIndex;
          });
        },
        settings: FlipSettings(
          showCover: true,
          drawShadow: true,
          flippingTime: 600,
        ),
        pageBuilder: (index, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: _pageColors[index % _pageColors.length],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Page ${index + 1}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This is the content of page ${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```


## Architecture

This package provides the following architecture:

### Core Components

1. **TurnablePage** - Main widget that provides the page-flipping interface
2. **TurnablePageView** - Internal view that handles rendering and animations  
3. **PageFlipController** - Controller for programmatic page management
4. **PageFlip** - Core logic engine that handles flip calculations and state
5. **FlipSettings** - Configuration object for customizing behavior

### Key Features

- **Widget-Based Pages**: Use any Flutter widget as page content through the `pageBuilder` function
- **Hardware Acceleration**: Leverages Flutter's rendering engine for smooth animations
- **Responsive Design**: Automatic adaptation between portrait and landscape modes
- **Touch Gestures**: Full support for swipe, drag, and tap interactions
- **Event System**: Comprehensive callbacks for page change events
- **Customizable Styling**: Extensive configuration options for appearance and behavior

### Performance Tips

1. **Optimize Page Content**: Keep page widgets lightweight and avoid heavy computations in `pageBuilder`
2. **Use Appropriate Pixel Ratio**: Higher values improve quality but impact performance
3. **Limit Page Count**: Very large books may impact memory usage
4. **Efficient Assets**: Keep media lightweight; image-based page examples will be added in a future update

### Responsive Design

```dart
// Automatic responsive behavior
TurnablePage(
  autoResponseSize: true,      // Adapts to device size only in single mode
  pageViewMode: PageViewMode.single, // Switches based on screen size
  // ...
)
```

### Custom Page Layouts

```dart
Widget buildCustomPage(int index, BoxConstraints constraints) {
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        // Header
        Container(
          height: 60,
          child: Text('Chapter $index'),
        ),
        
        // Content area
        Expanded(
          child: YourContentWidget(pageIndex: index),
        ),
        
        // Footer
        Container(
          height: 40,
          child: Text('Page ${index + 1}'),
        ),
      ],
    ),
  );
}
```

## Troubleshooting

### Common Issues

**Pages not rendering correctly:**
- Ensure `pageCount` matches your actual content
- Check that `pageBuilder` returns valid widgets for all indices
- Verify container constraints are properly set

**Performance issues:**
- Reduce `pixelRatio` if animations are choppy
- Optimize page widget complexity
- Consider lazy loading for large content

**Touch gestures not working:**
- Ensure `mobileScrollSupport` is enabled
- Check `swipeDistance` threshold
- Verify no conflicting gesture detectors in parent widgets

**Layout issues on different screen sizes:**
- Use `autoResponseSize: true` for automatic adaptation
- Test on various screen sizes and orientations
- Consider using `LayoutBuilder` for custom responsive behavior

 

## Roadmap

- [x] Core page flipping logic
- [x] Widget-based pages  
- [x] Touch/gesture handling
- [x] Interactive content support
- [x] Smart gesture detection
- [x] Event system and callbacks
- [x] Hardware-accelerated rendering with RenderBox
- [x] Responsive design support
- [x] Portrait/landscape orientation
- [x] Customizable animations and physics
- [ ] PDF document support
- [ ] Enhanced accessibility features
- [ ] Advanced animation customization
- [ ] Bookmark and navigation features

## Migration Guide (v0.x → v1.0.0)

### 🎉 Good News
If you were using the basic `TurnablePage` widget, **no code changes are required**! The API remains the same.

### ✨ What's New
- **Interactive content now works** - buttons, inputs, and other widgets inside pages are fully functional
- **Smart gesture detection** - automatic differentiation between widget interaction and page flipping
- **Better performance** - migrated from CustomPainter to Flutter's native RenderBox system

### 🔧 Advanced Users
If you were using internal APIs or had custom implementations:
- The underlying rendering system has completely changed
- Custom painter-based extensions will need to be rewritten
- Animation system now uses SchedulerBinding instead of manual frame scheduling

## Contributing

Contributions are welcome! Feel free to open issues and PRs to improve the package.

### Development Setup

1. Clone the repository:
```bash
git clone https://github.com/saeedahmed725/turnable_page.git
cd turnable_page
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the example:
```bash
cd example
flutter run
```

### Guidelines

- Keep the public API stable when possible and document any changes
- Follow Flutter development best practices
- Include tests for new features
- Update documentation for any API changes
- Ensure backward compatibility

## License

This project is distributed under the Turnable Page Proprietary License (TPPL). Usage, redistribution, and modification are not permitted except via approved pull requests in the official GitHub repository. See the [LICENSE](LICENSE) file for full terms.

## Credits

- Built with ❤️ for the Flutter community

## Support

If you find this package helpful, please:
- ⭐ Star the repository on GitHub
- 🐛 Report issues on GitHub Issues
- 💡 Suggest features and improvements
- 📖 Contribute to documentation

For support and questions, please use GitHub Issues or start a discussion in the repository.
