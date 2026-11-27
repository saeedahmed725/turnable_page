/// An empty side of a book spread when `FlipSettings.showCover` is on and
/// two pages are shown.
///
/// The front cover is shown alone on the right, so the side to its left is
/// empty ([front]). The last page may also be alone, on the left, leaving the
/// side to its right empty ([back]). Fill these sides with
/// `TurnablePage.coverSideBuilder`, for example with endpapers or a logo.
enum CoverSide {
  /// The side next to the front cover (left of the first page).
  front,

  /// The side next to the back cover (right of the last page, when it is
  /// alone in its spread).
  back,
}
