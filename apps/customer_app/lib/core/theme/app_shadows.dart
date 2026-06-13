import 'package:flutter/material.dart';

/// Shared elevation shadows (CWT + app cards).
abstract final class AppShadows {
  static const cardSoft = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const floatingBar = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];

  static const verticalProduct = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}
