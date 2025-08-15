import 'package:flutter/rendering.dart';

/// Parent data storing the page index for each child page widget used by the
/// new RenderTurnableBook render object.
class TurnableParentData extends ContainerBoxParentData<RenderBox> {
  int pageIndex = 0;
  @override
  String toString() => 'TurnableParentData(index=$pageIndex, offset=$offset)';
}
