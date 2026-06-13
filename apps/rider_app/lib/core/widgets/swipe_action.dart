import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/feedback_service.dart';
import '../theme/app_colors.dart';

/// A slide-to-confirm control: the rider must drag a handle across a track to
/// trigger [onConfirmed]. Used by both accept (Requirement 3) and confirm
/// (Requirement 4) flows.
///
/// Behavior:
/// - [onConfirmed] fires only when the handle is dragged past the confirm
///   threshold (≈85% of the track). A short drag springs back and does
///   nothing (Requirements 3.6, 4.6, 4.7).
/// - On a completed swipe, haptic feedback is triggered via
///   [FeedbackService.onConfirm] (Requirements 7.2, 7.3).
/// - If [onConfirmed] throws, the handle springs back to the start and the
///   control becomes usable again, supporting accept/confirm-failure
///   re-enable (Requirements 3.10, 4.10).
/// - While [enabled] is false the handle cannot be dragged and never fires.
/// - Themed with the active teal palette in both light and dark themes
///   (Requirement 11.4).
///
/// [feedbackService] is injectable so tests can supply a fake and avoid real
/// platform haptics; it defaults to a new [FeedbackService].
class SwipeAction extends StatefulWidget {
  const SwipeAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onConfirmed,
    this.enabled = true,
    this.feedbackService,
  });

  /// Label rendered along the track (e.g. "Swipe to accept").
  final String label;

  /// Icon shown inside the draggable handle.
  final IconData icon;

  /// Whether the control accepts drags. When false the handle is locked and
  /// [onConfirmed] never fires.
  final bool enabled;

  /// Invoked once the handle crosses the confirm threshold. If it throws, the
  /// handle springs back and the control re-enables.
  final Future<void> Function() onConfirmed;

  /// Optional injected feedback service (defaults to a new [FeedbackService]).
  /// Exposed for testing without real platform haptics.
  final FeedbackService? feedbackService;

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<SwipeAction>
    with SingleTickerProviderStateMixin {
  static const double _trackHeight = 64;
  static const double _handleSize = 56;
  static const double _trackPadding = 4;

  /// Fraction of the track the handle must cross for the action to fire.
  static const double _confirmThresholdFraction = 0.85;

  late final FeedbackService _feedbackService;
  late final AnimationController _animationController;
  Animation<double>? _glideAnimation;

  /// Current handle offset from the start of the track, in logical pixels.
  double _dragExtent = 0;

  /// Maximum handle offset (track width minus handle and padding).
  double _maxExtent = 0;

  /// True while [SwipeAction.onConfirmed] is in flight.
  bool _isProcessing = false;

  /// True once a swipe has successfully confirmed; the handle stays at the end
  /// and the control locks until the parent rebuilds it.
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final animation = _glideAnimation;
        if (animation != null) {
          setState(() => _dragExtent = animation.value);
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Whether the rider can currently interact with the handle.
  bool get _interactive => widget.enabled && !_isProcessing && !_isConfirmed;

  double get _confirmThreshold => _maxExtent * _confirmThresholdFraction;

  /// Smoothly animates the handle from its current position to [target].
  Future<void> _glideTo(double target) {
    _glideAnimation = Tween<double>(begin: _dragExtent, end: target).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    return _animationController.forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_interactive) return;
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dx).clamp(0.0, _maxExtent);
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (!_interactive) return;
    if (_maxExtent > 0 && _dragExtent >= _confirmThreshold) {
      await _glideTo(_maxExtent);
      await _confirm();
    } else {
      await _glideTo(0);
    }
  }

  /// Fires the confirm callback once the handle has crossed the threshold.
  ///
  /// Triggers haptic feedback, then awaits [SwipeAction.onConfirmed]. On
  /// success the handle locks at the end; if it throws, the handle springs
  /// back to the start and the control re-enables (Requirements 3.10, 4.10).
  Future<void> _confirm() async {
    setState(() => _isProcessing = true);
    await _feedbackService.onConfirm();
    try {
      await widget.onConfirmed();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isConfirmed = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      await _glideTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool active = widget.enabled && !_isProcessing;

    final Color trackColor = active
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.primaryLight)
        : (isDark ? AppColors.surfaceElevated : AppColors.borderLight);
    final Color fillColor = AppColors.primary.withValues(alpha: 0.32);
    final Color handleColor = active ? AppColors.primary : AppColors.textDisabled;
    final Color labelColor = active
        ? (isDark ? AppColors.textInverse : AppColors.primaryDark)
        : AppColors.textDisabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        _maxExtent = (trackWidth - _handleSize - _trackPadding * 2)
            .clamp(0.0, double.infinity);

        // Fade the label out as the handle slides toward the end.
        final double progress =
            _maxExtent == 0 ? 0 : (_dragExtent / _maxExtent).clamp(0.0, 1.0);
        final double labelOpacity = (1 - progress * 1.6).clamp(0.0, 1.0);

        return Container(
          height: _trackHeight,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(_trackHeight / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress fill trailing the handle.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: _dragExtent + _handleSize + _trackPadding,
                  decoration: BoxDecoration(
                    color: active ? fillColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                  ),
                ),
              ),
              // Centered label.
              Opacity(
                opacity: labelOpacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _handleSize),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
              ),
              // Draggable handle.
              Positioned(
                left: _trackPadding + _dragExtent,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: handleColor,
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            _isConfirmed ? LucideIcons.check : widget.icon,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
