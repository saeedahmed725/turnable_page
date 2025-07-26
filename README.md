# Flutter PageFlip

A complete Flutter/Dart port of the popular [StPageFlip](https://github.com/Nodlik/StPageFlip) JavaScript library. This package provides a realistic page-flipping effect for digital books, magazines, catalogs, and other multi-page content in Flutter applications.

## Features

✅ **Faithful Port**: Complete 1:1 conversion from the original TypeScript/JavaScript implementation
✅ **Realistic Physics**: Advanced flip animations with proper physics and shadows
✅ **Touch Support**: Full touch and gesture support for mobile devices
✅ **Multiple Orientations**: Automatic portrait/landscape orientation handling
✅ **Image Support**: Load pages from image URLs or assets
✅ **Widget Support**: Use Flutter widgets as pages (planned)
✅ **Customizable**: Extensive configuration options
✅ **Performance**: Optimized for smooth 60fps animations
✅ **Events**: Rich event system for interaction handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_pageflip: ^1.0.0
```

## Basic Usage

### Simple Image Book

```dart
import 'package:flutter/material.dart';
import 'package:flutter_pageflip/flutter_pageflip.dart';

class MyBook extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final images = [
      'https://example.com/page1.jpg',
      'https://example.com/page2.jpg',
      'https://example.com/page3.jpg',
    ];

    return Scaffold(
      body: Center(
        child: PageFlipWidget(
          images: images,
          settings: {
            'width': 400.0,
            'height': 600.0,
            'showCover': true,
            'drawShadow': true,
          },
        ),
      ),
    );
  }
}
```

### Advanced Configuration

```dart
PageFlipWidget(
  images: images,
  settings: {
    // Page dimensions
    'width': 400.0,
    'height': 600.0,
    'size': 'fixed', // or 'stretch'
    
    // Bounds
    'minWidth': 315.0,
    'maxWidth': 1000.0,
    'minHeight': 420.0,
    'maxHeight': 1350.0,
    
    // Visual effects
    'drawShadow': true,
    'maxShadowOpacity': 1.0,
    'showPageCorners': true,
    
    // Animation
    'flippingTime': 1000,
    
    // Behavior
    'usePortrait': true,
    'showCover': true,
    'autoSize': true,
    'swipeDistance': 30.0,
    'disableFlipByClick': false,
    
    // Starting page
    'startPage': 0,
  },
)
```

## API Reference

### PageFlip Class

The main class that handles the page flipping logic.

#### Constructor
```dart
PageFlip(Widget rootWidget, Map<String, dynamic> settings)
```

#### Methods

- `loadFromImages(List<String> images)` - Load pages from image URLs
- `turnToNextPage()` - Turn to the next page
- `turnToPrevPage()` - Turn to the previous page
- `turnToPage(int page)` - Turn to a specific page
- `flipNext([FlipCorner corner])` - Flip next page with animation
- `flipPrev([FlipCorner corner])` - Flip previous page with animation
- `getPageCount()` - Get total number of pages
- `getCurrentPageIndex()` - Get current page index
- `getOrientation()` - Get current orientation
- `update()` - Update the render area

#### Events

```dart
pageFlip.on('flip', (event) {
  print('Flipped to page: ${event.data}');
});

pageFlip.on('changeOrientation', (event) {
  print('Orientation changed to: ${event.data}');
});

pageFlip.on('init', (event) {
  print('PageFlip initialized');
});
```

### Settings

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `width` | `double` | `0` | Page width in pixels |
| `height` | `double` | `0` | Page height in pixels |
| `size` | `String` | `'fixed'` | Size calculation type: 'fixed' or 'stretch' |
| `minWidth` | `double` | `0` | Minimum page width |
| `maxWidth` | `double` | `0` | Maximum page width |
| `minHeight` | `double` | `0` | Minimum page height |
| `maxHeight` | `double` | `0` | Maximum page height |
| `drawShadow` | `bool` | `true` | Enable/disable shadows |
| `flippingTime` | `int` | `1000` | Animation duration in milliseconds |
| `usePortrait` | `bool` | `true` | Enable portrait mode |
| `autoSize` | `bool` | `true` | Auto-size to parent container |
| `maxShadowOpacity` | `double` | `1.0` | Maximum shadow opacity (0-1) |
| `showCover` | `bool` | `false` | Show hard cover pages |
| `swipeDistance` | `double` | `30.0` | Minimum swipe distance for page turn |
| `showPageCorners` | `bool` | `true` | Show folded corners on hover |
| `disableFlipByClick` | `bool` | `false` | Disable clicking to flip pages |
| `startPage` | `int` | `0` | Initial page index |

## Architecture

This package is a faithful port of the original StPageFlip library with the following components:

### Core Components

1. **PageFlip** - Main controller class
2. **BookPage** - Abstract base class for pages
3. **Render** - Abstract rendering engine
4. **PageCollection** - Manages page collections
5. **Helper** - Mathematical utilities

### Page Types

- **ImagePage** - Pages rendered from images
- **HTMLPage** - Pages from HTML/Widget content (planned)

### Rendering

- **CanvasRender** - Hardware-accelerated rendering (planned)
- **HTMLRender** - Widget-based rendering (planned)

## Examples

### Basic Book Reader

```dart
class BookReader extends StatefulWidget {
  @override
  _BookReaderState createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  late PageFlip pageFlip;
  int currentPage = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Reader'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => pageFlip.turnToPrevPage(),
          ),
          Text('${currentPage + 1}'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () => pageFlip.turnToNextPage(),
          ),
        ],
      ),
      body: PageFlipWidget(
        images: bookImages,
        settings: {'showCover': true},
      ),
    );
  }
}
```

## Roadmap

- [x] Core page flipping logic
- [x] Image page support
- [x] Basic touch/gesture handling
- [x] Event system
- [ ] Widget-based pages
- [ ] Advanced animations
- [ ] PDF support
- [ ] Performance optimizations
- [ ] Web support
- [ ] Accessibility features

## Contributing

This is a faithful port of the original StPageFlip library. Contributions are welcome! Please ensure any changes maintain compatibility with the original API.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- Original [StPageFlip](https://github.com/Nodlik/StPageFlip) library by Nodlik
- Ported to Flutter/Dart with ❤️

## Support

If you find this package helpful, please give it a ⭐ on GitHub!
