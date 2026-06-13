import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/services/feedback_service.dart';
import 'providers/order_providers.dart';

bool _isAssignmentExpired(Map<String, dynamic> assignment) {
  final raw = assignment['expiresAt']?.toString();
  if (raw == null || raw.isEmpty) return false;
  final expiresAt = DateTime.tryParse(raw);
  if (expiresAt == null) return false;
  return expiresAt.isBefore(DateTime.now());
}

/// Buffers [assignment] and opens the incoming-order screen when the rider
/// has no active delivery.
void presentIncomingAssignmentIfIdle(
  WidgetRef ref,
  BuildContext context,
  Map<String, dynamic> assignment,
) {
  if (_isAssignmentExpired(assignment)) {
    debugPrint('[AssignTrace] skip present expired assignment');
    return;
  }

  final assignmentId = assignment['assignmentId']?.toString();
  if (assignmentId == null || assignmentId.isEmpty) return;

  final lastPresented = ref.read(lastPresentedAssignmentIdProvider);
  if (lastPresented == assignmentId) {
    debugPrint('[AssignTrace] skip present duplicate lastPresented=$assignmentId');
    return;
  }
  final lastAccepted = ref.read(lastAcceptedAssignmentIdProvider);
  if (lastAccepted == assignmentId) {
    debugPrint('[AssignTrace] skip present alreadyAccepted=$assignmentId');
    return;
  }

  ref.read(pendingAssignmentProvider.notifier).set(assignment);

  final activeAssignment = ref.read(activeAssignmentProvider);
  if (activeAssignment != null) {
    debugPrint(
      '[AssignTrace] skip present busy assignmentId=$assignmentId activeAssignment=${activeAssignment['assignmentId']}',
    );
    return;
  }

  // Prevent stacking duplicate incoming screens on top of each other.
  final route = GoRouterState.of(context).matchedLocation;
  if (route == RoutePaths.incomingOrder) {
    debugPrint('[AssignTrace] skip present alreadyOnIncoming route');
    return;
  }

  ref.read(activeAssignmentProvider.notifier).set(assignment);
  ref.read(pendingAssignmentProvider.notifier).set(null);
  ref.read(lastPresentedAssignmentIdProvider.notifier).set(assignmentId);
  debugPrint('[AssignTrace] presenting assignmentId=$assignmentId');
  ref.read(feedbackServiceProvider).onIncomingAssignment();
  context.push(RoutePaths.incomingOrder, extra: assignment);
}

/// After delivery completes, show a buffered offer if one arrived mid-trip.
void tryPresentPendingAssignment(WidgetRef ref, BuildContext context) {
  final pending = ref.read(pendingAssignmentProvider);
  if (pending == null) return;
  presentIncomingAssignmentIfIdle(ref, context, Map<String, dynamic>.from(pending));
}

/// Clears active delivery state when a trip ends.
///
/// Does not clear [pendingAssignmentProvider] — an offer may have arrived
/// during the trip and must survive until presentation or API sync.
void clearRiderDeliveryState(WidgetRef ref) {
  ref.read(activeOrderProvider.notifier).set(null);
  ref.read(activeAssignmentProvider.notifier).set(null);
  ref.read(deliveryStepProvider.notifier).set(0);
}
