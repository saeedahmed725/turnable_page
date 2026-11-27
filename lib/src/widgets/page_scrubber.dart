import 'package:flutter/widgets.dart';

import 'page_flip_controller.dart';

/// Builds the label next to a [PageScrubber], such as "3 / 12".
typedef PageScrubberLabelBuilder =
    Widget Function(BuildContext context, int pageIndex, int pageCount);

/// Builds the preview shown above the thumb while dragging, usually a small
/// version of the page.
typedef PageScrubberPreviewBuilder =
    Widget Function(BuildContext context, int pageIndex);

/// A page slider for a book: drag or tap to go to any page.
///
/// It follows [controller], so it moves when pages are turned, and it jumps
/// (or turns, with [animate]) to the chosen page on release. Every part can
/// be styled or replaced: colors and sizes, the label ([labelBuilder]), and
/// a page preview while dragging ([previewBuilder]). It uses only the
/// widgets library, so it fits Material, Cupertino or custom designs.
///
/// ```dart
/// Column(children: [
///   Expanded(child: TurnablePage(controller: controller, ...)),
///   PageScrubber(
///     controller: controller,
///     previewBuilder: (context, i) => Image.asset('thumbs/$i.jpg'),
///   ),
/// ])
/// ```
///
/// In a right-to-left context (or with [textDirection]) the track runs from
/// right to left, like the book.
class PageScrubber extends StatefulWidget {
  const PageScrubber({
    super.key,
    required this.controller,
    this.height = 44,
    this.trackHeight = 4,
    this.thumbRadius = 8,
    this.activeColor = const Color(0xFFA4471C),
    this.inactiveColor = const Color(0x33000000),
    this.thumbColor,
    this.thumbBuilder,
    this.showLabel = true,
    this.labelBuilder,
    this.labelStyle,
    this.previewBuilder,
    this.previewSize = const Size(72, 100),
    this.animate = false,
    this.onChanged,
    this.textDirection,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// The book's controller.
  final PageFlipController controller;

  /// Total height of the scrubber.
  final double height;

  /// Thickness of the track.
  final double trackHeight;

  /// Radius of the default thumb.
  final double thumbRadius;

  /// Color of the track up to the current page.
  final Color activeColor;

  /// Color of the rest of the track.
  final Color inactiveColor;

  /// Color of the default thumb. Defaults to [activeColor].
  final Color? thumbColor;

  /// Replaces the default round thumb. `dragging` is true while it is held.
  final Widget Function(BuildContext context, bool dragging)? thumbBuilder;

  /// Whether to show the label after the track.
  final bool showLabel;

  /// Builds the label. Defaults to "3 / 12".
  final PageScrubberLabelBuilder? labelBuilder;

  /// Style of the default label.
  final TextStyle? labelStyle;

  /// Builds a preview of the page under the thumb while dragging. Without
  /// it, no preview is shown.
  final PageScrubberPreviewBuilder? previewBuilder;

  /// Size of the preview.
  final Size previewSize;

  /// Turn to the chosen page with an animation instead of jumping.
  final bool animate;

  /// Called with the page under the thumb while dragging.
  final ValueChanged<int>? onChanged;

  /// Direction of the track. Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// Space around the track and label.
  final EdgeInsetsGeometry padding;

  @override
  State<PageScrubber> createState() => _PageScrubberState();
}

class _PageScrubberState extends State<PageScrubber> {
  /// Page under the thumb while dragging, or null.
  int? _dragPage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(PageScrubber old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted && _dragPage == null) setState(() {});
  }

  int get _count => widget.controller.pageCount;

  int _pageAt(double dx, double width, bool rtl) {
    if (_count <= 1 || width <= 0) return 0;
    var t = (dx / width).clamp(0.0, 1.0);
    if (rtl) t = 1 - t;
    return (t * (_count - 1)).round();
  }

  void _update(double dx, double width, bool rtl) {
    final page = _pageAt(dx, width, rtl);
    if (page != _dragPage) {
      setState(() => _dragPage = page);
      widget.onChanged?.call(page);
    }
  }

  void _commit() {
    final page = _dragPage;
    setState(() => _dragPage = null);
    if (page == null || page == widget.controller.currentPageIndex) return;
    if (widget.animate) {
      widget.controller.animateToPage(page);
    } else {
      widget.controller.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl =
        (widget.textDirection ??
            Directionality.maybeOf(context) ??
            TextDirection.ltr) ==
        TextDirection.rtl;
    final count = _count;
    final page = (_dragPage ?? widget.controller.currentPageIndex).clamp(
      0,
      count > 0 ? count - 1 : 0,
    );
    final dragging = _dragPage != null;

    Widget? label;
    if (widget.showLabel && count > 0) {
      label =
          widget.labelBuilder?.call(context, page, count) ??
          Text(
            '${page + 1} / $count',
            style:
                widget.labelStyle ??
                TextStyle(
                  color: widget.activeColor,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          );
    }

    final track = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final r = widget.thumbRadius;
        final usable = (width - 2 * r).clamp(0.0, double.infinity);
        var t = count > 1 ? page / (count - 1) : 0.0;
        if (rtl) t = 1 - t;
        final thumbX = r + usable * t;
        final centerY = widget.height / 2;

        final thumb =
            widget.thumbBuilder?.call(context, dragging) ??
            Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(
                color: widget.thumbColor ?? widget.activeColor,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 3),
                ],
              ),
            );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) =>
              _update(d.localPosition.dx - r, usable, rtl),
          onHorizontalDragUpdate: (d) =>
              _update(d.localPosition.dx - r, usable, rtl),
          onHorizontalDragEnd: (_) => _commit(),
          onHorizontalDragCancel: () => setState(() => _dragPage = null),
          onTapUp: (d) {
            _update(d.localPosition.dx - r, usable, rtl);
            _commit();
          },
          child: SizedBox(
            height: widget.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Track.
                Positioned(
                  left: r,
                  right: r,
                  top: centerY - widget.trackHeight / 2,
                  height: widget.trackHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.inactiveColor,
                      borderRadius: BorderRadius.circular(widget.trackHeight),
                    ),
                  ),
                ),
                // Read part.
                Positioned(
                  left: rtl ? thumbX : r,
                  right: rtl ? r : width - thumbX,
                  top: centerY - widget.trackHeight / 2,
                  height: widget.trackHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      borderRadius: BorderRadius.circular(widget.trackHeight),
                    ),
                  ),
                ),
                Positioned(
                  left: thumbX - r,
                  top: centerY - r,
                  width: r * 2,
                  height: r * 2,
                  child: thumb,
                ),
                if (dragging && widget.previewBuilder != null)
                  Positioned(
                    left: (thumbX - widget.previewSize.width / 2).clamp(
                      0.0,
                      (width - widget.previewSize.width).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    bottom: widget.height - centerY + r + 8,
                    width: widget.previewSize.width,
                    height: widget.previewSize.height,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(color: Color(0x55000000), blurRadius: 8),
                          ],
                        ),
                        child: widget.previewBuilder!(context, page),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          Expanded(child: track),
          if (label != null) ...[const SizedBox(width: 12), label],
        ],
      ),
    );
  }
}
