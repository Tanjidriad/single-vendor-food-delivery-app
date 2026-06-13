import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Helpers for announcing status changes to assistive technology.
///
/// Requirements 20.7 and 20.8: when content changes dynamically (filtering,
/// sorting, pagination, validation errors) or a status message is produced
/// (success confirmations, error notifications, loading states), the change
/// SHALL be announced to screen readers without requiring the user to navigate
/// to the message location.
///
/// [SemanticsService.sendAnnouncement] posts a message directly to the platform
/// accessibility layer for a specific [FlutterView], so the user hears it
/// regardless of focus position. This complements the in-tree
/// `Semantics(liveRegion: true)` regions used by components such as the data
/// table and form fields.
abstract final class A11yAnnouncer {
  /// Announces [message] to assistive technology for the view that hosts
  /// [context].
  ///
  /// No-ops for an empty/blank [message]. Safe to call from any layer; on
  /// platforms without an active screen reader the call is simply ignored.
  static void announce(BuildContext context, String message) {
    if (message.trim().isEmpty) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(
      view,
      message,
      Directionality.of(context),
    );
  }
}
