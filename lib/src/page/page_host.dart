import 'package:flutter/widgets.dart';

import '../render/turnable_parent_data.dart';
import '../widgets/turnable_book_render_object_widget.dart';

/// A [ParentDataWidget] that associates a [pageIndex] with each page's render object
/// inside [TurnableBookRenderObjectWidget].
class PageHost extends ParentDataWidget<TurnableParentData> {
  final int index;

  const PageHost({
    super.key,
    required this.index,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    if (renderObject.parentData is TurnableParentData) {
      final parentData = renderObject.parentData! as TurnableParentData;
      if (parentData.pageIndex != index) {
        parentData.pageIndex = index;
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => TurnableBookRenderObjectWidget;
}
