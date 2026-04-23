import 'package:flutter/material.dart';
import 'package:manager/core/utils/app_responsive.dart';

class AppSquareIcon extends StatelessWidget {
  final String? status;
  final IconData icon;
  final double? size;

  const AppSquareIcon({
    super.key,
    required this.icon,
    this.status,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Logic xác định màu sắc dựa trên status
    Color getBaseColor() {
      final String s = status?.toLowerCase() ?? '';

      switch (s) {
        case 'active':
        case 'paid':
        case 'received':
          return Colors.green;
        case 'draft':
          return Colors.orange; // Yellow/Orange để hiển thị rõ trên nền trắng
        case 'sent':
        case 'ordered':
          return Colors.blue.shade300; // Blue nhạt
        case 'overdue':
        case 'inactive':
        case 'cancelled': // Thêm theo yêu cầu
          return cs.error;
        default:
          return cs.tertiary; // Mặc định là Tertiary theo yêu cầu
      }
    }

    final baseColor = getBaseColor();
    final double widgetSize = size ?? context.rw(52);

    return Container(
      width: widgetSize,
      height: widgetSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor,
            baseColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.rr(14)),
        border: Border.all(
          color: Colors.white
              .withOpacity(0.1), // Viền trắng mảnh giúp icon nổi hơn
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white, // Chuyển sang trắng để nổi bật trên nền màu đậm
        size: (widgetSize * 0.5),
      ),
    );
  }
}
