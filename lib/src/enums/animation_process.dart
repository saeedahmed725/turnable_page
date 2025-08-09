typedef FrameAction = void Function();
typedef AnimationSuccessAction = void Function();

/// Type describing the animation process
/// Only one animation process can be started at a same time
class AnimationProcess {
  /// List of frames in playback order. Each frame is a function.
  final List<FrameAction> frames;

  /// Total animation duration
  final double duration;

  /// Animation duration of one frame
  final double durationFrame;

  /// Callback at the end of the animation
  final AnimationSuccessAction onAnimateEnd;

  /// Animation start time (Global Timer)
  final double startedAt;

  const AnimationProcess({
    required this.frames,
    required this.duration,
    required this.durationFrame,
    required this.onAnimateEnd,
    required this.startedAt,
  });
}
