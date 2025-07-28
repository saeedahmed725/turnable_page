/// State of the book
enum FlippingState {
  /// The user folding the page
  userFold('user_fold'),

  /// Mouse over active corners
  foldCorner('fold_corner'),

  /// During flipping animation
  flipping('flipping'),

  /// Base state
  read('read');

  const FlippingState(this.value);
  final String value;
}
