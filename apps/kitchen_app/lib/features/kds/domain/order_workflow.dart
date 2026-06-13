/// The single source of truth for normalized order status semantics.
enum CanonicalOrderStatus {
  pendingKitchenAcceptance,
  acceptedByKitchen,
  preparing,
  readyForPickup,
  logistics, // picked up / on the way
  delivered,
  returnedToRestaurant,
  rejectedByKitchen,
  cancelledByCustomer,
  cancelledBySystem,
  ignoredTestOrder,
  unknown
}

/// The distinct UI sections in the Kitchen Display System
enum KitchenSection {
  newOrders,
  preparing,
  ready,
  returned,
  history,
  ignored, // not shown normally
  hidden
}

/// The stage-based timer type
enum TimerType {
  acceptance,
  preparation,
  pickupWait,
  delivery,
  none
}

class OrderWorkflowMapper {
  /// Maps the backend raw status and metadata to our CanonicalOrderStatus.
  /// When [includeTestOrders] is true, test orders are mapped by status so they
  /// can appear in active KDS sections; otherwise they are forced to ignored.
  static CanonicalOrderStatus getCanonicalStatus(
    Map<String, dynamic> order, {
    bool includeTestOrders = false,
  }) {
    if (!includeTestOrders &&
        (order['isTest'] == true || order['ignoreInReporting'] == true)) {
      return CanonicalOrderStatus.ignoredTestOrder;
    }

    final status = order['status'] as String?;
    final cancelledBy = order['cancelledBy'] as String?;

    switch (status) {
      case 'PLACED':
        return CanonicalOrderStatus.pendingKitchenAcceptance;
      case 'ACCEPTED':
        return CanonicalOrderStatus.acceptedByKitchen;
      case 'PREPARING':
        return CanonicalOrderStatus.preparing;
      case 'READY_FOR_PICKUP':
        return CanonicalOrderStatus.readyForPickup;
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return CanonicalOrderStatus.logistics;
      case 'DELIVERED':
        return CanonicalOrderStatus.delivered;
      case 'RETURNED_TO_RESTAURANT':
        return CanonicalOrderStatus.returnedToRestaurant;
      case 'REJECTED':
        return CanonicalOrderStatus.rejectedByKitchen;
      case 'CANCELLED':
        if (cancelledBy == 'SYSTEM') return CanonicalOrderStatus.cancelledBySystem;
        return CanonicalOrderStatus.cancelledByCustomer;
      default:
        return CanonicalOrderStatus.unknown;
    }
  }

  /// Maps the CanonicalOrderStatus to the correct KitchenSection tab.
  static KitchenSection getSection(CanonicalOrderStatus canonical) {
    switch (canonical) {
      case CanonicalOrderStatus.pendingKitchenAcceptance:
        return KitchenSection.newOrders;
      case CanonicalOrderStatus.acceptedByKitchen:
      case CanonicalOrderStatus.preparing:
        return KitchenSection.preparing;
      case CanonicalOrderStatus.readyForPickup:
        return KitchenSection.ready;
      case CanonicalOrderStatus.returnedToRestaurant:
        return KitchenSection.returned;
      case CanonicalOrderStatus.delivered:
      case CanonicalOrderStatus.rejectedByKitchen:
      case CanonicalOrderStatus.cancelledByCustomer:
      case CanonicalOrderStatus.cancelledBySystem:
        return KitchenSection.history;
      case CanonicalOrderStatus.ignoredTestOrder:
        return KitchenSection.ignored;
      case CanonicalOrderStatus.logistics:
      case CanonicalOrderStatus.unknown:
        return KitchenSection.hidden;
    }
  }

  /// Returns the appropriate TimerType based on canonical status.
  static TimerType getTimerType(CanonicalOrderStatus canonical) {
    switch (canonical) {
      case CanonicalOrderStatus.pendingKitchenAcceptance:
        return TimerType.acceptance;
      case CanonicalOrderStatus.acceptedByKitchen:
      case CanonicalOrderStatus.preparing:
        return TimerType.preparation;
      case CanonicalOrderStatus.readyForPickup:
        return TimerType.pickupWait;
      case CanonicalOrderStatus.logistics:
        return TimerType.delivery;
      default:
        return TimerType.none;
    }
  }

  /// Extracts the correct start anchor for the given TimerType.
  static DateTime? getTimerAnchor(Map<String, dynamic> order, TimerType timerType) {
    String? dateStr;
    switch (timerType) {
      case TimerType.acceptance:
        dateStr = order['placedAt'] ?? order['createdAt'];
        break;
      case TimerType.preparation:
        dateStr = order['prepStartedAt'] ?? order['acceptedAt'];
        break;
      case TimerType.pickupWait:
        dateStr = order['readyAt'];
        break;
      case TimerType.delivery:
        dateStr = order['pickedUpAt'];
        break;
      case TimerType.none:
        return null;
    }

    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Returns the human-readable prefix for the timer based on the active timer type.
  static String getTimerLabelPrefix(TimerType timerType) {
    switch (timerType) {
      case TimerType.acceptance:
        return 'Accept within';
      case TimerType.preparation:
        return 'Preparing for';
      case TimerType.pickupWait:
        return 'Ready since';
      case TimerType.delivery:
        return 'Delivering for';
      case TimerType.none:
        return '';
    }
  }
}
