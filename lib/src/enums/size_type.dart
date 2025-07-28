/// Book size calculation type
enum SizeType {
  /// Dimensions are fixed to the specified width and height values
  /// Use this when you want exact pixel dimensions regardless of container size
  fixed('fixed'),

  /// Dimensions are calculated based on the parent element's available space
  /// Use this when you want the book to fill or fit within its container
  stretch('stretch');

  const SizeType(this.value);
  final String value;
}
