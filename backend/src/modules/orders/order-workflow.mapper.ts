import { OrderStatus } from '@prisma/client';

export enum CanonicalOrderStatus {
  PENDING_KITCHEN_ACCEPTANCE = 'pending_kitchen_acceptance',
  ACCEPTED_BY_KITCHEN = 'accepted_by_kitchen',
  PREPARING = 'preparing',
  READY_FOR_PICKUP = 'ready_for_pickup',
  LOGISTICS = 'logistics',
  DELIVERED = 'delivered',
  REJECTED_BY_KITCHEN = 'rejected_by_kitchen',
  CANCELLED_BY_CUSTOMER = 'cancelled_by_customer',
  CANCELLED_BY_SYSTEM = 'cancelled_by_system',
  IGNORED_TEST_ORDER = 'ignored_test_order',
  UNKNOWN = 'unknown'
}

export enum KitchenSection {
  NEW_ORDERS = 'new_orders',
  PREPARING = 'preparing',
  READY = 'ready',
  HISTORY = 'history',
  IGNORED = 'ignored',
  HIDDEN = 'hidden'
}

export enum TimerType {
  ACCEPTANCE = 'acceptance',
  PREPARATION = 'preparation',
  PICKUP_WAIT = 'pickup_wait',
  DELIVERY = 'delivery',
  NONE = 'none'
}

export class OrderWorkflowMapper {
  static getCanonicalStatus(
    status: OrderStatus,
    isTest: boolean,
    ignoreInReporting: boolean,
    cancelledBy?: 'CUSTOMER' | 'SYSTEM' | 'KITCHEN'
  ): CanonicalOrderStatus {
    if (isTest || ignoreInReporting) {
      return CanonicalOrderStatus.IGNORED_TEST_ORDER;
    }

    switch (status) {
      case OrderStatus.PLACED:
        return CanonicalOrderStatus.PENDING_KITCHEN_ACCEPTANCE;
      case OrderStatus.ACCEPTED:
        return CanonicalOrderStatus.ACCEPTED_BY_KITCHEN;
      case OrderStatus.PREPARING:
        return CanonicalOrderStatus.PREPARING;
      case OrderStatus.READY_FOR_PICKUP:
        return CanonicalOrderStatus.READY_FOR_PICKUP;
      case OrderStatus.PICKED_UP:
      case OrderStatus.ON_THE_WAY:
        return CanonicalOrderStatus.LOGISTICS;
      case OrderStatus.DELIVERED:
        return CanonicalOrderStatus.DELIVERED;
      case OrderStatus.REJECTED:
        return CanonicalOrderStatus.REJECTED_BY_KITCHEN;
      case OrderStatus.CANCELLED:
        if (cancelledBy === 'SYSTEM') return CanonicalOrderStatus.CANCELLED_BY_SYSTEM;
        return CanonicalOrderStatus.CANCELLED_BY_CUSTOMER;
      case OrderStatus.IGNORED_TEST:
        return CanonicalOrderStatus.IGNORED_TEST_ORDER;
      default:
        return CanonicalOrderStatus.UNKNOWN;
    }
  }

  static getSection(canonical: CanonicalOrderStatus): KitchenSection {
    switch (canonical) {
      case CanonicalOrderStatus.PENDING_KITCHEN_ACCEPTANCE:
        return KitchenSection.NEW_ORDERS;
      case CanonicalOrderStatus.ACCEPTED_BY_KITCHEN:
      case CanonicalOrderStatus.PREPARING:
        return KitchenSection.PREPARING;
      case CanonicalOrderStatus.READY_FOR_PICKUP:
        return KitchenSection.READY;
      case CanonicalOrderStatus.DELIVERED:
      case CanonicalOrderStatus.REJECTED_BY_KITCHEN:
      case CanonicalOrderStatus.CANCELLED_BY_CUSTOMER:
      case CanonicalOrderStatus.CANCELLED_BY_SYSTEM:
        return KitchenSection.HISTORY;
      case CanonicalOrderStatus.IGNORED_TEST_ORDER:
        return KitchenSection.IGNORED;
      case CanonicalOrderStatus.LOGISTICS:
      case CanonicalOrderStatus.UNKNOWN:
      default:
        return KitchenSection.HIDDEN;
    }
  }

  static getTimerType(canonical: CanonicalOrderStatus): TimerType {
    switch (canonical) {
      case CanonicalOrderStatus.PENDING_KITCHEN_ACCEPTANCE:
        return TimerType.ACCEPTANCE;
      case CanonicalOrderStatus.ACCEPTED_BY_KITCHEN:
      case CanonicalOrderStatus.PREPARING:
        return TimerType.PREPARATION;
      case CanonicalOrderStatus.READY_FOR_PICKUP:
        return TimerType.PICKUP_WAIT;
      case CanonicalOrderStatus.LOGISTICS:
        return TimerType.DELIVERY;
      default:
        return TimerType.NONE;
    }
  }
}
