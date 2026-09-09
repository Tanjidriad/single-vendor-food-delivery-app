import 'package:flutter/foundation.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import 'print_preview_controller.dart';
import 'print_service.dart';

/// Sunmi built-in printer on V2/V2s devices; safe no-op on other hardware.
/// In debug mode without hardware, emits to PrintPreviewController instead.
class SunmiPrintService implements PrintService {
  bool _initialized = false;
  bool _available = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final bound = await SunmiPrinter.bindingPrinter();
      _available = bound == true;
      if (_available) await SunmiPrinter.initPrinter();
    } catch (e) {
      if (kDebugMode) debugPrint('[SunmiPrint] init failed: $e');
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
  Future<void> printOrderReceipt(Map<String, dynamic> order) =>
      printKitchenTicket(order);

  @override
  Future<void> printKitchenTicket(Map<String, dynamic> order) async {
    await initialize();
    if (!_available) {
      if (kDebugMode) {
        debugPrint(
          '[SunmiPrint] No Sunmi printer — KOT for #${order['orderNumber']}',
        );
        PrintPreviewController.instance.emit(
          PrintPreviewEvent(
            type: PrintPreviewType.kitchenTicket,
            content: _buildKitchenTicketContent(order),
          ),
        );
      }
      return;
    }
    try {
      await SunmiPrinter.printText(
        _buildKitchenTicketContent(order),
        style: SunmiTextStyle(
          align: SunmiPrintAlign.LEFT,
          fontSize: 26,
          bold: true,
        ),
      );
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();
    } catch (e) {
      if (kDebugMode) debugPrint('[SunmiPrint] print failed: $e');
    }
  }

  @override
  Future<void> printEndOfDayReport(List<dynamic> orders) async {
    await initialize();
    if (!_available) {
      if (kDebugMode) {
        debugPrint('[SunmiPrint] No Sunmi printer — skipping Z-Report print');
        PrintPreviewController.instance.emit(
          PrintPreviewEvent(
            type: PrintPreviewType.zReport,
            content: _buildZReportContent(orders),
          ),
        );
      }
      return;
    }
    try {
      await SunmiPrinter.printText(
        _buildZReportContent(orders),
        style: SunmiTextStyle(
          align: SunmiPrintAlign.LEFT,
          fontSize: 24,
          bold: true,
        ),
      );
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();
    } catch (e) {
      if (kDebugMode) debugPrint('[SunmiPrint] Z-Report print failed: $e');
    }
  }

  String _buildKitchenTicketContent(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final serial = order['dailySerial'];
    final serialText = serial is int
        ? '#${serial.toString().padLeft(3, '0')}'
        : '';
    final buffer = StringBuffer()
      ..writeln('KITCHEN ORDER')
      ..writeln(
        serialText.isNotEmpty
            ? serialText
            : '#${order['orderNumber'] ?? '---'}',
      )
      ..writeln('Ref: ${order['orderNumber'] ?? '---'}')
      ..writeln('Type: ${order['orderType'] ?? ''}')
      ..writeln('Status: ${order['status'] ?? ''}')
      ..writeln('------------------------------');

    for (final raw in items) {
      if (raw is! Map) continue;
      final qty = raw['quantity'] ?? 1;
      final name = raw['name'] ?? 'Item';
      buffer.writeln('${qty}x $name');
      final addons = raw['addons'] as List<dynamic>?;
      if (addons != null) {
        for (final a in addons) {
          if (a is Map) buffer.writeln('   + ${a['name']}');
        }
      }
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
    return buffer.toString();
  }

  String _buildZReportContent(List<dynamic> orders) {
    double netFoodSales = 0;
    double totalSubtotal = 0;
    double totalTax = 0;
    double totalPackaging = 0;
    double totalDeliveryFee = 0;
    int cashOrders = 0;
    int digitalOrders = 0;

    for (final order in orders) {
      final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
      final tax = (order['taxAmount'] as num?)?.toDouble() ?? 0.0;
      final packaging = (order['packagingFee'] as num?)?.toDouble() ?? 0.0;
      final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;

      totalSubtotal += subtotal;
      totalTax += tax;
      totalPackaging += packaging;
      totalDeliveryFee += deliveryFee;
      netFoodSales += subtotal + tax + packaging;

      final method = order['paymentMethod']?.toString().toUpperCase() ?? '';
      if (method == 'COD' || method == 'CASH') {
        cashOrders++;
      } else {
        digitalOrders++;
      }
    }

    return (StringBuffer()
          ..writeln('END OF DAY REPORT (Z-REPORT)')
          ..writeln(
            'Date: ${DateTime.now().toLocal().toString().split('.')[0]}',
          )
          ..writeln('------------------------------')
          ..writeln('Total Orders: ${orders.length}')
          ..writeln(' - Cash Orders: $cashOrders')
          ..writeln(' - Digital Orders: $digitalOrders')
          ..writeln('------------------------------')
          ..writeln('SALES BREAKDOWN')
          ..writeln('Subtotals:       BDT ${totalSubtotal.toStringAsFixed(2)}')
          ..writeln('Packaging Fees:  BDT ${totalPackaging.toStringAsFixed(2)}')
          ..writeln('Tax/VAT:         BDT ${totalTax.toStringAsFixed(2)}')
          ..writeln('------------------------------')
          ..writeln('NET FOOD SALES:  BDT ${netFoodSales.toStringAsFixed(2)}')
          ..writeln('------------------------------')
          ..writeln(
            'Delivery Fees:   BDT ${totalDeliveryFee.toStringAsFixed(2)}',
          )
          ..writeln('------------------------------')
          ..writeln('Printed by Kitchen OS'))
        .toString();
  }
}
