/// Controls how pages are displayed in the book.
enum PageViewMode {
  /// Displays a single page (portrait) regardless of container width.
  single,

  /// Displays two pages side-by-side (spread / landscape) regardless of container width.
  double,

  /// Automatically adapts based on container width: single page on narrow screens (< 600px),
  /// double-page spread on wide screens (>= 600px).
  auto,
}
