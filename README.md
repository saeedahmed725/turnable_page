# Turnable Page: realistic page flip for Flutter

[![pub package](https://img.shields.io/pub/v/turnable_page.svg)](https://pub.dev/packages/turnable_page)
[![pub points](https://img.shields.io/pub/points/turnable_page)](https://pub.dev/packages/turnable_page/score)
[![likes](https://img.shields.io/pub/likes/turnable_page)](https://pub.dev/packages/turnable_page)
[![docs](https://img.shields.io/badge/docs-website-a4471c)](https://saeedahmed725.github.io/turnable_page/)

🇪🇬 [اقرأ بالعربي](README_AR.md)

A high-performance Flutter package that provides a realistic **3D page-flipping (page curl) effect** for digital books, magazines, catalogs, **PDFs**, and other interactive multi-page content in Flutter applications. Build flipbooks, e-books, Quran and manga readers, and PDF page-turn viewers, where every page is a normal, fully interactive Flutter widget.

📖 **[Read the full documentation →](https://saeedahmed725.github.io/turnable_page/)**

| Two-page spread (desktop) | Single page (mobile) | Responsive `auto` mode |
|:---:|:---:|:---:|
| ![Flutter page flip animation in a two-page book spread](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/desktop-fliping.gif) | ![Flutter page curl animation on mobile, single page](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/mobile-fliping.gif) | ![Flutter flipbook switching between single and double page](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/responsiveness.gif) |

## Features

- **Realistic page curl**: bending paper, a white back side, and shadows on the fold, the spine and the page below.
- **Interactive pages**: buttons, text fields and scroll views inside a page keep working. Pages are live widgets, not screenshots.
- **Single, double or `auto` layout**: one page on phones, a two-page spread on tablets and desktop.
- **PDF flipbook**: open a PDF from an asset, a URL or a file with `TurnablePdf`. Links in the PDF are tappable, and zoomed pages stay sharp.
- **Image books**: comics, manga, catalogs and photo albums with `TurnableImages`, with the next pages loaded ahead.
- **Hard covers**: covers (or every page) swing as stiff boards instead of bending.
- **Page edges**: thin stacks beside the pages show how much is left. In a spread, the left one grows and the right one shrinks as you read. A single page shows only the stack of pages left to read.
- **Page scrubber**: a slider to jump to any page, with an optional page preview. Every part can be styled.
- **Corner hints**: a corner folds slightly under the mouse, or once when the book opens, to show that pages turn.
- **Auto-play** for slideshows and kiosks.
- **Pinch-to-zoom** with an optional double-tap zoom.
- **Sound and haptics**: a light vibration on each turn, and an `onPageTurn` callback to play your own page-turn sound.
- **Keyboard, mouse wheel and screen readers**: arrow keys, Page Up/Down, Home/End and the mouse wheel turn pages, and screen readers announce "Page 3 of 10".
- **Dark mode**: shadows adapt to dark paper. Optional glossy paper for magazines.
- **Reduce motion**: turns get shorter when the system asks for less animation.
- **RTL books** for Arabic, Hebrew, Persian and Urdu, with mirrored page turns.
- **Controller**: next, previous, animate or jump to any page, and listen to page events.
- **Large books**: only the pages near the current one are built.

## Installation

```yaml
dependencies:
  turnable_page: ^2.2.0
```

```dart
import 'package:turnable_page/turnable_page.dart';
```

## Quick start

```dart
TurnablePage(
  pageCount: 10,
  pageViewMode: PageViewMode.auto,
  builder: (context, pageIndex, constraints) {
    return ColoredBox(
      color: Colors.white,
      child: Center(child: Text('Page ${pageIndex + 1}')),
    );
  },
  onPageChanged: (leftIndex, rightIndex) {
    debugPrint('Showing $leftIndex / $rightIndex');
  },
)
```

Drag a page or tap it to turn it. The book sizes itself to fit its parent while keeping `aspectRatio`.

## Page layout: single, double or auto

| `PageViewMode` | Behavior |
|---|---|
| `single` (default) | One page at a time. |
| `double` | Two-page book spread. |
| `auto` | One page under 600 px of width, two pages from 600 px. |

Set `FlipSettings(showCover: true)` to show the first and last pages alone, like a hardcover book. The sides next to them are empty: fill them with `coverSideBuilder`, for example with endpapers or a logo.

```dart
TurnablePage(
  pageViewMode: PageViewMode.double,
  settings: FlipSettings(showCover: true),
  coverSideBuilder: (context, side, constraints) => side == CoverSide.front
      ? const Endpaper(text: 'This book belongs to…')
      : const Endpaper(text: 'The End'),
  // ...
)
```

## Navigate with `PageFlipController`

```dart
final controller = PageFlipController();

TurnablePage(controller: controller, pageCount: 20, builder: buildPage);

await controller.nextPage();      // animated, completes when the turn ends
await controller.previousPage();
await controller.animateToPage(7);
controller.jumpToPage(3);         // instant

controller.currentPageIndex;      // 0-based
controller.hasNextPage;
controller.hasClients;            // true once the book is on screen
```

Every navigation method returns `false` when the page index is out of range or no book is attached. To react to events, use `controller.addEventListener(PageFlipEvent.flip, (e) => ...)`.

The controller is a `ChangeNotifier`, so `ListenableBuilder` rebuilds your UI on each page change:

```dart
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => Text('${controller.currentPageIndex + 1} / ${controller.pageCount}'),
)
```

**Auto-play** turns pages on a timer. It stops at the last page (or starts over with `loop: true`), and when the reader touches the book:

```dart
controller.startAutoPlay(interval: const Duration(seconds: 4), loop: true);
controller.stopAutoPlay();
```

## Page scrubber

`PageScrubber` is a slider for the book: drag or tap it to go to any page. It follows page turns.

```dart
Column(children: [
  Expanded(child: TurnablePage(controller: controller, ...)),
  PageScrubber(
    controller: controller,
    activeColor: Colors.brown,
    previewBuilder: (context, i) => Image.asset('thumbs/$i.jpg'), // optional
  ),
])
```

Every part can be changed: `height`, `trackHeight`, `thumbRadius`, `activeColor`, `inactiveColor`, `thumbColor`, your own thumb (`thumbBuilder`), the label (`showLabel`, `labelBuilder`, `labelStyle`), the preview size, `animate` (turn instead of jump), `padding` and `textDirection`. In a right-to-left book the track runs from right to left.

## Interactive pages and taps

By default, a tap on an empty part of a page turns it, and the page corners are reserved for turning. Buttons, links and text fields (anything with a clickable mouse cursor) stay tappable even on a corner. If your pages have many tap targets (links, verses), turn tap-to-flip off:

```dart
TurnablePage(
  settings: FlipSettings(flipOnTap: false),
  // ...
)
```

Taps then always reach the page, and pages turn only by dragging (corners included) or from the controller. Vertical scroll views inside a page scroll normally. A mostly horizontal drag turns the page.

## Pinch-to-zoom

```dart
TurnablePage(
  enableZoom: true,
  minScale: 1.0,
  maxScale: 3.0,
  // ...
)
```

While a page is zoomed in, dragging pans the page instead of turning it. By default, a double tap zooms in and out. Set `enableDoubleTapZoom: false` to keep pinch-to-zoom and use double tap for your own gesture, such as toggling the reader UI. To reset the zoom from code, call `controller.resetZoom()`.

## Sound, haptics and keyboard

```dart
TurnablePage(
  settings: FlipSettings(
    hapticFeedback: true,       // light vibration on each turn
    mouseWheelNavigation: true, // wheel or trackpad turns pages
  ),
  onPageTurn: (direction) => player.play('page_turn.mp3'),
  // ...
)
```

`onPageTurn` is called once for each turn that will complete, when the page starts moving on its own, with `FlipDirection.forward` or `FlipDirection.back`. Cancelled drags are not reported. Play the sound with any audio package.

Keyboard navigation is on by default. Once the book is tapped or clicked, the arrow keys, Page Up/Down and Space turn one page, and Home/End go to the first and last page. In a right-to-left book the left arrow turns forward. Set `keyboardNavigation: false` to turn it off.

Screen readers announce the current page and can turn pages with the adjust gestures. To translate the text, pass `semanticsValueBuilder: (i, count) => 'صفحة ${i + 1} من $count'`.

## Image books

```dart
TurnableImages.network(
  [for (int i = 1; i <= 24; i++) 'https://example.com/comic/$i.jpg'],
  pageViewMode: PageViewMode.auto,
  aspectRatio: 2 / 3,
)
```

`TurnableImages(images: [...])` takes any `ImageProvider`s, and `TurnableImages.asset([...])` asset paths. The images around the current page are loaded ahead (`precacheExtent`, default 2), so a turn never shows an empty page. Set `fit`, `pageColor`, `loadingBuilder` and `errorBuilder` to style the pages.

## PDF page flip viewer

Initialize the PDF engine once, before `runApp`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TurnablePdf.initPDFLoaders();
  runApp(const MyApp());
}
```

Then open the document:

```dart
TurnablePdf.asset('assets/catalog.pdf', pageViewMode: PageViewMode.auto);
TurnablePdf.network('https://example.com/magazine.pdf', headers: {'Authorization': token});
TurnablePdf.file('/path/to/book.pdf');
```

`TurnablePdf` accepts the same `controller`, `settings`, `onPageChanged` and `textDirection` as `TurnablePage`, plus `loadingBuilder` and `errorBuilder`. PDF rendering is provided by [pdfrx](https://pub.dev/packages/pdfrx).

Links in the PDF are tappable (`enableLinks`, on by default): a link to another page turns to it. Pass `onLinkTap: (link) => ...` to open web links, for example with url_launcher. With zoom on, pages are rendered at a higher resolution so text stays sharp when zoomed in.

## Right-to-left books

```dart
TurnablePage(
  textDirection: TextDirection.rtl, // or leave null to follow Directionality
  // ...
)
```

Page 1 is on the right and pages turn from left to right.

## Styling

**A real book**:

```dart
FlipSettings(
  hardCover: true,      // covers swing as stiff boards (or hardPages: every page)
  showPageEdges: true,  // page stacks beside the pages show what is left
  pageEdgeWidth: 6,     // width of a full stack
  paperGloss: 0.6,      // glossy magazine paper, 0 (matte) to 1
)
```

**Corner hints**: on desktop and web, a corner folds slightly when the mouse comes near it (`showPageCorners`, on by default; `cornerHoverSize` sets the area). `peekOnOpen: true` folds the first page's corner once when the book appears, and `controller.peek()` does it on demand.

**Reduce motion**: when the system asks for less animation, turns last at most 200 ms. Set `respectReducedMotion: false` to ignore it.

**Paper and shadows**:

```dart
FlipSettings(
  flippingTime: 600,                     // turn duration in ms
  pageBackgroundColor: Color(0xFF1E1E1E), // match dark pages to avoid light edges
  drawShadow: true,
  showCenterShadow: true,                 // spine shadow in a two-page spread
  centerShadowColor: Colors.black,
  innerShadowColor: Colors.black,
  outerShadowColor: Colors.black,
)
```

## API reference

### `TurnablePage`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `pageCount` | `int` | required | Number of pages. |
| `builder` | `TurnableBuilder` | required | `(context, pageIndex, constraints)` → page widget. |
| `pageViewMode` | `PageViewMode?` | `single` | `single`, `double` or `auto`. |
| `controller` | `PageFlipController?` | `null` | Navigation and state. |
| `onPageChanged` | `TurnablePageCallback?` | `null` | `(leftIndex, rightIndex)`, called once each turn completes. |
| `settings` | `FlipSettings?` | `FlipSettings()` | Behavior and appearance (see below). |
| `aspectRatio` | `double?` | `2/3` per page | Width ÷ height of one page. |
| `textDirection` | `TextDirection?` | ambient | `ltr` or `rtl`. |
| `pageCacheExtent` | `int` | `4` | Pages kept built on each side of the current page. |
| `onPageTurn` | `void Function(FlipDirection)?` | `null` | Called once for each turn that will complete. Use it for a page-turn sound. |
| `semanticsValueBuilder` | `String Function(int, int)?` | `null` | Screen reader text for the current page. Defaults to "Page 3 of 10". |
| `coverSideBuilder` | `CoverSideBuilder?` | `null` | `(context, side, constraints)` → widget for the empty side next to a cover (`showCover` in a spread). |
| `enableZoom` | `bool?` | `false` | Pinch-to-zoom. |
| `enableDoubleTapZoom` | `bool?` | `true` | Double tap toggles zoom when `enableZoom` is on. |
| `minScale` / `maxScale` | `double?` | `1.0` / `3.0` | Zoom limits. |

### `FlipSettings`

| Parameter | Default | Description |
|---|---|---|
| `startPageIndex` | `0` | First page shown. Initial value only: use the controller to navigate later. |
| `flippingTime` | `700` | Turn animation duration in ms. |
| `showCover` | `false` | Show the first and last pages alone, like covers. |
| `flipOnTap` | `true` | Tap to turn and reserve the corners for turning. Set to `false` for tappable page content. |
| `cornerTriggerAreaSize` | `0.2` | Size of the corner hot zone, as a fraction of the page diagonal. |
| `enableInertia` | `true` | A fast fling finishes the turn. |
| `enableEasing` | `true` | Eased turn animation. |
| `onlyVerticalPageFlip` | `false` | Turn pages with vertical drags only. |
| `hapticFeedback` | `false` | Light vibration on each turn. |
| `keyboardNavigation` | `true` | Arrow keys, Page Up/Down, Space, Home and End turn pages when the book has focus. |
| `mouseWheelNavigation` | `false` | The mouse wheel or a trackpad scroll turns pages. |
| `drawShadow` | `true` | All turn shadows. |
| `showCenterShadow` | `true` | Spine shadow in a two-page spread. |
| `centerShadowColor`, `innerShadowColor`, `outerShadowColor` | `Colors.black` | Shadow colors. |
| `maxShadowOpacity` | `1.0` | Shadow strength, from 0 to 1. |
| `adaptiveShadows` | `true` | Stronger shadows on dark paper, where black shadows lose contrast. |
| `pageBackgroundColor` | white | Paper color behind and under pages. |
| `hardCover` / `hardPages` | `false` | Covers, or every page, turn as stiff boards. |
| `showPageEdges` / `pageEdgeWidth` | `false` / `6` | Page stacks beside the pages, growing and shrinking as you read. |
| `paperGloss` | `0` | Glossy paper, from 0 (matte) to 1. |
| `showPageCorners` / `cornerHoverSize` | `true` / `64` | Fold a corner slightly under the mouse, within this many pixels of it. |
| `peekOnOpen` | `false` | Fold the first page's corner once when the book appears. |
| `respectReducedMotion` | `true` | Shorter turns when the system asks for less animation. |

The full list, including the bend and inertia tuning values, is in the [API docs](https://pub.dev/documentation/turnable_page/latest/turnable_page/FlipSettings-class.html).

## Documentation

The [documentation website](https://saeedahmed725.github.io/turnable_page/) covers every feature in depth: gestures, events, PDF loading, styling, the full `FlipSettings` reference, recipes, migrating to 2.0, and troubleshooting.

## Example app

See [`example/`](https://github.com/saeedahmed725/turnable_page/tree/main/example) for a complete demo with all modes, PDF loading and controller usage.

## Contributing

Bug reports and feature requests are welcome on the [issue tracker](https://github.com/saeedahmed725/turnable_page/issues). Pull requests go through the official repository.

## License

Turnable Page Proprietary License (TPPL) v1.1. You may use the package, unmodified, in any app, commercial apps included. Modifying, copying, redistributing or selling the package itself needs written permission. See [LICENSE](LICENSE).
