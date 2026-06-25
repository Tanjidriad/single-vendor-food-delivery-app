import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sunmi_print_service.dart';

final printServiceProvider = Provider<PrintService>((ref) {
  return SunmiPrintService();
});

/// Abstract base class for printing functionality.
abstract class PrintService {
  Future<void> initialize();
  Future<bool> connect();
  Future<void> printOrderReceipt(Map<String, dynamic> order);
  Future<void> printKitchenTicket(Map<String, dynamic> order);
  Future<void> printEndOfDayReport(List<dynamic> orders);
}
