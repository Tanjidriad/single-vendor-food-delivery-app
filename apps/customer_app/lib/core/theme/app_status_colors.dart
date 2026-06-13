import 'package:flutter/material.dart';

abstract final class AppStatusColors {
  static const placed = Color(0xFF6B6B6B);
  static const accepted = Color(0xFF457B9D);
  static const preparing = Color(0xFFE85D04);
  static const ready = Color(0xFF7B2CBF);
  static const pickedUp = Color(0xFF0F766E);
  static const onTheWay = Color(0xFF0D9488);
  static const delivered = Color(0xFF2D6A4F);
  static const cancelled = Color(0xFFD62828);

  static Color forStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return accepted;
      case 'PREPARING':
        return preparing;
      case 'READY_FOR_PICKUP':
        return ready;
      case 'PICKED_UP':
        return pickedUp;
      case 'ON_THE_WAY':
        return onTheWay;
      case 'DELIVERED':
        return delivered;
      case 'CANCELLED':
        return cancelled;
      default:
        return placed;
    }
  }
}
