import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';

/// A stage-based SLA timer for kitchen operations.
class OrderStageTimer extends StatefulWidget {
  final TimerType timerType;
  final DateTime? startTime;
  final String labelPrefix;
  final int slaThresholdSeconds;
  final bool compact;

  const OrderStageTimer({
    super.key,
    required this.timerType,
    required this.startTime,
    required this.labelPrefix,
    required this.slaThresholdSeconds,
    this.compact = false,
  });

  @override
  State<OrderStageTimer> createState() => _OrderStageTimerState();
}

class _OrderStageTimerState extends State<OrderStageTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    if (widget.timerType != TimerType.none && widget.startTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateElapsed();
      });
    }
  }

  @override
  void didUpdateWidget(OrderStageTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timerType != widget.timerType || oldWidget.startTime != widget.startTime) {
      _timer?.cancel();
      if (widget.timerType != TimerType.none && widget.startTime != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateElapsed();
        });
      }
    }
    _updateElapsed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    if (widget.startTime == null) return;
    
    // For pickupWait, if we are in history, it should technically freeze at pickedUpAt.
    // However, if the TimerType is none, the timer won't be rendered or updated.
    final now = DateTime.now();
    setState(() {
      _elapsed = now.difference(widget.startTime!);
    });
  }

  Color get _urgencyColor {
    final halfSla = widget.slaThresholdSeconds ~/ 2;
    if (_elapsed.inSeconds < halfSla) {
      return AppColors.success;
    } else if (_elapsed.inSeconds < widget.slaThresholdSeconds) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String get _formattedTime {
    final mins = _elapsed.inMinutes;
    final secs = _elapsed.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startTime == null || widget.timerType == TimerType.none) {
      return const SizedBox.shrink();
    }

    final color = _urgencyColor;

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formattedTime,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formattedTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (widget.labelPrefix.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              widget.labelPrefix,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
