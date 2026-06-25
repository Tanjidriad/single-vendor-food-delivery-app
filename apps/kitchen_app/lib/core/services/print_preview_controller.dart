import 'dart:async';

/// Global sink for debug print previews.
/// SunmiPrintService pushes events here when no printer is available.
/// PrintPreviewOverlay listens and shows the receipt dialog.
class PrintPreviewController {
  PrintPreviewController._();
  static final PrintPreviewController instance = PrintPreviewController._();

  final _controller = StreamController<PrintPreviewEvent>.broadcast();

  Stream<PrintPreviewEvent> get stream => _controller.stream;

  void emit(PrintPreviewEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}

enum PrintPreviewType { kitchenTicket, zReport }

class PrintPreviewEvent {
  final PrintPreviewType type;
  final String content;
  const PrintPreviewEvent({required this.type, required this.content});
}
