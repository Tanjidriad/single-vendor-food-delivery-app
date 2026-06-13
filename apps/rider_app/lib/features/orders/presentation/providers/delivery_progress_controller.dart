import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/delivery_state_model.dart';
import '../../data/orders_repository.dart';
import 'order_providers.dart';

/// The outcome of confirming the current delivery step.
///
/// The screen uses this to decide what to do after the swipe-to-confirm
/// completes — notably whether to present the proof-of-delivery flow
/// (Requirement 4.8).
enum DeliveryConfirmResult {
  /// The order status was updated and [deliveryStepProvider] advanced to the
  /// next step (Requirements 4.6, 4.7).
  advanced,

  /// The current step has no status update; the screen should present the
  /// proof-of-delivery flow (Requirement 4.8).
  proofOfDelivery,

  /// The order-status update failed; [deliveryStepProvider] is unchanged and an
  /// error is surfaced via [DeliveryProgressState.error] (Requirement 4.10).
  failed,

  /// A confirmation was already in flight, so this activation was ignored.
  ignored,
}

/// Observable view-state for the active delivery confirm control.
///
/// [isUpdating] is true while an order-status update is in flight (used to show
/// a loading indicator and to ignore re-entrant confirmations). [error] carries
/// a user-facing message when the last update failed (Requirement 4.10); it is
/// `null` while there is no error.
@immutable
class DeliveryProgressState {
  final bool isUpdating;
  final String? error;

  const DeliveryProgressState({this.isUpdating = false, this.error});

  DeliveryProgressState copyWith({
    bool? isUpdating,
    String? error,
    bool clearError = false,
  }) {
    return DeliveryProgressState(
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DeliveryProgressState &&
      other.isUpdating == isUpdating &&
      other.error == error;

  @override
  int get hashCode => Object.hash(isUpdating, error);

  @override
  String toString() =>
      'DeliveryProgressState(isUpdating: $isUpdating, error: $error)';
}

/// Encapsulates the active delivery step → order-status state machine.
///
/// Drives the swipe-to-confirm control on the Active_Delivery_Screen through
/// the [DeliveryStateModel] mapping, preserving the step-retention-on-failure
/// behavior the screen relies on (Requirement 4.10 / Correctness Property 9).
///
/// Behavior, keyed to the current [deliveryStepProvider] value and the active
/// order id (from [activeOrderProvider]):
/// - Steps with a status ([DeliveryStateModel.statusForStep] non-null, i.e.
///   step 0 → `PICKED_UP`, step 1 → `ON_THE_WAY`): the order-status update is
///   issued; on success [deliveryStepProvider] advances to
///   [DeliveryStateModel.nextStep] (Requirements 4.6, 4.7); on failure the step
///   is left unchanged and an error is surfaced (Requirement 4.10).
/// - Step 2 (status `null`): no update is issued; the controller signals that
///   the proof-of-delivery flow should be presented (Requirement 4.8).
/// - Re-entrant confirmations while an update is in flight are ignored.
///
/// The repository is obtained from [ordersRepositoryProvider], so tests can
/// override that provider with a failing/succeeding mock to assert step
/// retention (task 11.3 / Property 9).
class DeliveryProgressController extends Notifier<DeliveryProgressState> {
  @override
  DeliveryProgressState build() => const DeliveryProgressState();

  /// Pure mapping from a delivery step to the order status to send, delegating
  /// to [DeliveryStateModel] (exposed for the screen and tests).
  static String? statusForStep(int step) =>
      DeliveryStateModel.statusForStep(step);

  /// Confirms the current delivery step.
  ///
  /// Reads the current [deliveryStepProvider] value and the active order id,
  /// then either updates the order status and advances the step, or signals the
  /// proof-of-delivery flow. Returns a [DeliveryConfirmResult] describing the
  /// outcome so the screen can react (e.g. present the POD sheet).
  Future<DeliveryConfirmResult> confirmCurrentStep() async {
    // Ignore confirmations while an update is in flight. The loading flag is
    // set synchronously below before the first await, so synchronous
    // re-entrant calls observe it and return early.
    if (state.isUpdating) return DeliveryConfirmResult.ignored;

    final step = ref.read(deliveryStepProvider);

    // Step 3+ is the proof-of-delivery terminal step — route to the OTP flow
    // (Requirement 4.8). No repository call is made.
    if (DeliveryStateModel.isProofOfDeliveryStep(step)) {
      return DeliveryConfirmResult.proofOfDelivery;
    }

    final status = DeliveryStateModel.statusForStep(step);

    // Step 0 has no backend status (the rider just arrived at the restaurant);
    // advance to the next step without an API call.
    if (status == null) {
      final next = DeliveryStateModel.nextStep(step);
      if (next != null) {
        ref.read(deliveryStepProvider.notifier).set(next);
      }
      return DeliveryConfirmResult.advanced;
    }

    final order = ref.read(activeOrderProvider);
    final orderId = order?['id'] as String? ?? '';
    if (orderId.isEmpty) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Active order is missing. Please reopen the assignment.',
      );
      return DeliveryConfirmResult.failed;
    }

    state = state.copyWith(isUpdating: true, clearError: true);
    try {
      await ref.read(ordersRepositoryProvider).updateOrderStatus(
            orderId,
            status,
          );
      // Success: advance to the next step (Requirements 4.6, 4.7). nextStep is
      // non-null here because statusForStep was non-null.
      final next = DeliveryStateModel.nextStep(step);
      if (next != null) {
        ref.read(deliveryStepProvider.notifier).set(next);
      }
      state = state.copyWith(isUpdating: false);
      return DeliveryConfirmResult.advanced;
    } catch (e) {
      // Failure: retain the current step and surface the error
      // (Requirement 4.10 / Property 9). deliveryStepProvider is intentionally
      // left untouched here.
      state = state.copyWith(
        isUpdating: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return DeliveryConfirmResult.failed;
    }
  }

  /// Clears any surfaced error (e.g. after it has been shown to the rider).
  void clearError() => state = state.copyWith(clearError: true);
}

final deliveryProgressControllerProvider =
    NotifierProvider<DeliveryProgressController, DeliveryProgressState>(
  () => DeliveryProgressController(),
);
