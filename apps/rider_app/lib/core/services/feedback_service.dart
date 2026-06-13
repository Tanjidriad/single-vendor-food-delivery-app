import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Default asset path (relative to the `assets/` root) for the
/// incoming-assignment alert sound.
///
/// Maps to `assets/sounds/alert.wav`. The asset file and a matching `assets:`
/// entry in `pubspec.yaml` must exist for the sound to play; if they are
/// missing, [FeedbackService.onIncomingAssignment] still vibrates and never
/// throws (Requirements 7.4, 7.5).
const String _defaultAlertAssetPath = 'sounds/alert.wav';

/// Plays a built-in platform alert sound (no bundled asset required) as a
/// fallback when the alert asset is missing or fails to play. This keeps the
/// incoming-assignment alert audible even before a custom asset is bundled
/// (Requirement 7.1).
Future<void> _defaultSystemAlert() => SystemSound.play(SystemSoundType.alert);

/// Device feedback (vibration, sound, and haptics) for key rider events.
///
/// Every capability is best-effort: each side effect is wrapped so that a
/// missing or unavailable capability never throws and never interrupts the
/// corresponding action (Requirement 7.5). Vibration is attempted
/// independently of sound so a muted device still buzzes on a new assignment
/// (Requirement 7.4).
///
/// The service is injectable for testing: callers may supply an [AudioPlayer],
/// an alert asset path, or override the vibrate/haptic/play callbacks directly
/// so tests need not touch real platform channels.
class FeedbackService {
  FeedbackService({
    AudioPlayer? audioPlayer,
    String alertAssetPath = _defaultAlertAssetPath,
    Future<void> Function()? vibrate,
    Future<void> Function()? haptic,
    Future<void> Function()? playAlertSound,
    Future<void> Function()? playSystemAlert,
  })  : _audioPlayer = audioPlayer,
        _alertAssetPath = alertAssetPath,
        _vibrate = vibrate ?? HapticFeedback.vibrate,
        _haptic = haptic ?? HapticFeedback.mediumImpact,
        _playAlertSoundOverride = playAlertSound,
        _playSystemAlert = playSystemAlert ?? _defaultSystemAlert;

  /// The audio player, created lazily on first use so that constructing the
  /// service (e.g. in tests with a [playAlertSound] override) never touches a
  /// platform channel.
  AudioPlayer? _audioPlayer;
  final String _alertAssetPath;
  final Future<void> Function() _vibrate;
  final Future<void> Function() _haptic;
  final Future<void> Function()? _playAlertSoundOverride;
  final Future<void> Function() _playSystemAlert;

  /// Triggers feedback for a newly arrived assignment: a device vibration and
  /// an alert sound (Requirement 7.1).
  ///
  /// Vibration is attempted independently of sound — each runs inside its own
  /// guard — so that a failure (or absence) of one never blocks the other, a
  /// muted device still buzzes (Requirement 7.4), and the method never throws
  /// (Requirement 7.5).
  Future<void> onIncomingAssignment() async {
    await _guard(_vibrate);
    await _guard(_playAlertSound);
  }

  /// Triggers haptic feedback when the rider completes a confirm/accept swipe
  /// (Requirements 7.2, 7.3).
  ///
  /// Wrapped so an unavailable haptic capability never throws (Requirement
  /// 7.5).
  Future<void> onConfirm() async {
    await _guard(_haptic);
  }

  /// Releases the underlying audio resources.
  Future<void> dispose() => _guard(() async => _audioPlayer?.dispose());

  /// Plays the alert sound for a new assignment, preferring the custom asset
  /// (or the injected primary sound) and falling back to a built-in platform
  /// alert sound when that fails — e.g. the asset is missing because no
  /// `assets:` entry is bundled yet (Requirement 7.1).
  Future<void> _playAlertSound() async {
    try {
      await _playPrimaryAlertSound();
    } catch (_) {
      // The custom alert asset is missing or failed to play (e.g. no
      // `assets:` entry yet). Fall back to a built-in platform alert sound so
      // a new assignment still produces an audible cue (Requirement 7.1).
      await _playSystemAlert();
    }
  }

  /// Plays the primary alert sound: the injected override when present,
  /// otherwise the bundled audio asset via [AudioPlayer].
  Future<void> _playPrimaryAlertSound() async {
    final override = _playAlertSoundOverride;
    if (override != null) {
      return override();
    }
    final player = _audioPlayer ??= AudioPlayer();
    // Set volume to max for urgent incoming assignment alerts
    await player.setVolume(1.0);
    await player.play(AssetSource(_alertAssetPath));
  }

  /// Runs [action], swallowing any error so a missing capability never
  /// interrupts the flow (Requirement 7.5).
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Intentionally ignored: feedback is best-effort and must never throw.
    }
  }
}

/// Provides the shared [FeedbackService] used for device vibration, alert
/// sound, and haptics on key rider events (Requirement 7).
///
/// Exposed as a Riverpod [Provider] so call sites (e.g. the home screen's
/// incoming-assignment listener) read a single instance and tests can override
/// it with a fake to assert that feedback fires without touching real platform
/// channels.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService();
  ref.onDispose(service.dispose);
  return service;
});
