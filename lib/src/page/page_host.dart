import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../render/turnable_parent_data.dart';

class PageHost extends SingleChildRenderObjectWidget {
  final int index;

  const PageHost({super.key, required this.index, required Widget child})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _PageRender(index);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _PageRender).index = index;
  }
}

class _PageRender extends RenderProxyBox {
  _PageRender(this.index);

  int index;

  @override
  void setupParentData(RenderObject child) {
    if (parentData is! TurnableParentData) parentData = TurnableParentData();
    (parentData as TurnableParentData).pageIndex = index;
  }
}
