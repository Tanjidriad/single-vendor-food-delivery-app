import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final orderAlertServiceProvider = Provider<OrderAlertService>((ref) {
  final service = OrderAlertService();
  ref.onDispose(service.dispose);
  return service;
});

/// Audible + haptic alert for new kitchen orders.
///
/// Uses [AudioPlayer] with a custom bundled WAV file for a loud, attention-
/// grabbing alert that kitchen staff can hear. Falls back to SystemSound if
/// the custom asset fails. Supports repeating the alert and stopping it.
class OrderAlertService {
  AudioPlayer? _player;
  bool _isPlaying = false;

  /// Whether the alert is currently playing/repeating.
  bool get isPlaying => _isPlaying;

  /// Plays the new-order alert sound with haptic feedback.
  ///
  /// [repeatCount] controls how many times the alert plays (default 3).
  /// Each repeat has a short gap between plays so it's clearly attention-
  /// grabbing without being a continuous drone.
  Future<void> playNewOrderSound({int repeatCount = 3}) async {
    // Haptic feedback first — works even if sound fails
    await _guardHaptic();

    _isPlaying = true;
    for (int i = 0; i < repeatCount && _isPlaying; i++) {
      try {
        await _playAlertOnce();
        // Wait a brief gap between repeats
        if (i < repeatCount - 1 && _isPlaying) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      } catch (_) {
        // Fall back to system sound on any failure
        await _playSystemFallback();
      }
    }
    _isPlaying = false;
  }

  /// Stops the currently playing alert (e.g. when staff acknowledges the order).
  Future<void> stopAlert() async {
    _isPlaying = false;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  /// Plays the custom WAV alert once at maximum volume.
  Future<void> _playAlertOnce() async {
    final player = _player ??= AudioPlayer();
    await player.setVolume(1.0);
    await player.play(AssetSource('sounds/new_order.wav'));
    // Wait for playback to complete
    await player.onPlayerComplete.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  /// Fallback: play the system alert sound.
  Future<void> _playSystemFallback() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Haptic feedback — wrapped so it never throws.
  Future<void> _guardHaptic() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Release audio resources.
  Future<void> dispose() async {
    _isPlaying = false;
    try {
      _player?.dispose();
    } catch (_) {}
  }
}

