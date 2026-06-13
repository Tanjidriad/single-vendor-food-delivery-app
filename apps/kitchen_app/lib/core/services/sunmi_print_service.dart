import 'package:flutter/foundation.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import 'print_service.dart';

/// Sunmi built-in printer on V2/V2s devices; safe no-op on other hardware.
class SunmiPrintService implements PrintService {
  bool _initialized = false;
  bool _available = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final bound = await SunmiPrinter.bindingPrinter();
      _available = bound == true;
      if (_available) {
        await SunmiPrinter.initPrinter();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SunmiPrint] init failed: $e');
      }
      _available = false;
    }
    _initialized = true;
  }

  @override
  Future<bool> connect() async {
    await initialize();
    return _available;
  }

  bool get isAvailable => _available;

  @override
  Future<void> printOrderReceipt(Map<String, dynamic> order) async {
    await printKitchenTicket(order);
  }

  @override
  Future<void> printKitchenTicket(Map<String, dynamic> order) async {
    await initialize();
    if (!_available) {
      if (kDebugMode) {
        debugPrint(
          '[SunmiPrint] No Sunmi printer — KOT for #${order['orderNumber']}',
        );
      }
      return;
    }

    final items = order['items'] as List<dynamic>? ?? [];
    final buffer = StringBuffer()
      ..writeln('KITCHEN ORDER')
      ..writeln('#${order['orderNumber'] ?? '---'}')
      ..writeln('Status: ${order['status'] ?? ''}')
      ..writeln('------------------------------');

    for (final raw in items) {
      if (raw is! Map) continue;
      final qty = raw['quantity'] ?? 1;
      final name = raw['name'] ?? 'Item';
      buffer.writeln('${qty}x $name');
      final notes = raw['notes']?.toString();
      if (notes != null && notes.isNotEmpty) {
        buffer.writeln('   * $notes');
      }
    }

    final note = order['deliveryNote']?.toString();
    if (note != null && note.isNotEmpty) {
      buffer
        ..writeln('------------------------------')
        ..writeln('Note: $note');
    }

    buffer.writeln('------------------------------');

    try {
      await SunmiPrinter.printText(
        buffer.toString(),
        style: SunmiTextStyle(
          align: SunmiPrintAlign.LEFT,
          fontSize: 26,
          bold: true,
        ),
      );
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SunmiPrint] print failed: $e');
      }
    }
  }
}
