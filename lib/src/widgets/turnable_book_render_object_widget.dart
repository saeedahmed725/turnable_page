import 'package:flutter/widgets.dart';

import '../../turnable_page.dart';
import '../page/page_flip.dart';
import '../page/page_host.dart';
import '../render/render_turnable_book.dart';

class TurnableBookRenderObjectWidget extends MultiChildRenderObjectWidget {
  final int pageCount;
  final PageWidgetBuilder? builder;
  final FlipSettings settings;
  final PageFlip pageFlip;
  final bool isZoomed;

  /// Children after the pages that hold the cover side widgets (0 or 2).
  final int coverSideCount;

  TurnableBookRenderObjectWidget({
    super.key,
    required this.pageCount,
    this.builder,
    required this.settings,
    required this.pageFlip,
    this.isZoomed = false,
    this.coverSideCount = 0,
    List<Widget>? children,
  }) : super(
         children:
             children ??
             List.generate(
               pageCount,
               (i) => PageHost(
                 key: ValueKey('page_host_$i'),
                 index: i,
                 child: builder != null
                     ? builder(WidgetsBinding.instance.rootElement!, i)
                     : const SizedBox.shrink(),
               ),
             ),
       );

  @override
  RenderTurnableBook createRenderObject(BuildContext context) {
    final render = RenderTurnableBook(settings, pageFlip);
    render.isZoomed = isZoomed;
    render.coverSideCount = coverSideCount;
    return render;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTurnableBook renderObject,
  ) {
    renderObject.updateSettings(settings);
    renderObject.isZoomed = isZoomed;
    renderObject.coverSideCount = coverSideCount;
  }
}
