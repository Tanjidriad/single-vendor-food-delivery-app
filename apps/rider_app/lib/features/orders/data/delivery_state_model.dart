/// Pure-logic model for the active delivery step state machine.
///
/// The active delivery flow advances through a sequence of integer steps held
/// by `deliveryStepProvider`:
///   0 = arrived at restaurant (UI-only confirmation, no backend call)
///   1 = confirm pickup (sends PICKED_UP)
///   2 = on the way to customer (sends ON_THE_WAY)
///   3 = at customer (proof-of-delivery / OTP)
///
/// This model maps each step to its UI stage, the order status to send on
/// confirming that step, and the next step.
///
/// It is intentionally free of any Flutter UI or map-SDK imports so it can be
/// property-tested independently (see Correctness Property 8).
library;

/// The stages shown in the horizontal step indicator.
enum DeliveryStage { restaurant, pickup, customer, delivered }

/// Pure mappings driving the delivery step state machine.
class DeliveryStateModel {
  const DeliveryStateModel._();

  /// Maps a [step] to the stage to highlight in the step indicator.
  ///
  /// - 0 -> [DeliveryStage.restaurant]
  /// - 1 -> [DeliveryStage.pickup]
  /// - 2 -> [DeliveryStage.customer]
  /// - 3+ -> [DeliveryStage.delivered]
  static DeliveryStage stageForStep(int step) {
    switch (step) {
      case 0:
        return DeliveryStage.restaurant;
      case 1:
        return DeliveryStage.pickup;
      case 2:
        return DeliveryStage.customer;
      default:
        return DeliveryStage.delivered;
    }
  }

  /// Maps a [step] to the order status to send when the rider confirms it.
  ///
  /// - 0 -> `null` (arrived at restaurant; UI-only, no backend status change)
  /// - 1 -> `'PICKED_UP'`
  /// - 2 -> `'ON_THE_WAY'`
  /// - 3+ -> `null` (proof-of-delivery flow; delivery is completed via OTP)
  static String? statusForStep(int step) {
    switch (step) {
      case 1:
        return 'PICKED_UP';
      case 2:
        return 'ON_THE_WAY';
      default:
        return null;
    }
  }

  /// Whether [step] is the proof-of-delivery step (terminal).
  ///
  /// At step 3 (and beyond), there is no backend status to send — the rider
  /// must complete the OTP-based proof-of-delivery flow instead. Step 0 also
  /// has no backend status, but it is NOT a POD step — it is a UI-only
  /// advancement.
  static bool isProofOfDeliveryStep(int step) => step >= 3;

  /// Maps a [step] to the next step after a successful confirmation.
  ///
  /// - 0 -> 1
  /// - 1 -> 2
  /// - 2 -> 3
  /// - 3+ -> `null` (terminal; proof-of-delivery completes the order)
  static int? nextStep(int step) {
    switch (step) {
      case 0:
        return 1;
      case 1:
        return 2;
      case 2:
        return 3;
      default:
        return null;
    }
  }
}
