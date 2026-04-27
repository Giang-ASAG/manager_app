import 'package:flutter/material.dart';
import 'package:manager/views/widgets/alerts/alert_widget.dart';

class TopAlert {
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green, Icons.check_circle);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red, Icons.error);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, Colors.orange, Icons.warning);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Colors.blue, Icons.info);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => TopAlertWidget(
        message: message,
        color: color,
        icon: icon,
        onClose: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}
