import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/core/utils/app_responsive.dart';

class ActionBottomButtons extends StatelessWidget {
  final bool isDeleting;
  final String editText;
  final String deleteText;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActionBottomButtons({
    super.key,
    required this.isDeleting,
    required this.editText,
    required this.deleteText,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.rw(16),
          context.rh(8),
          context.rw(16),
          context.rh(16),
        ),
        child: Row(
          children: [
            // Nút Chỉnh sửa
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleting ? null : onEdit,
                icon: Icon(Icons.edit_rounded, size: context.sp(18)),
                label: Text(editText),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: context.rh(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.rr(14)),
                  ),
                ),
              ),
            ),

            SizedBox(width: context.rw(12)),

            // Nút Xóa
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.white,
                        size: context.sp(28),
                      )
                    : Icon(Icons.delete_rounded, size: context.sp(18)),
                label: Text(
                  isDeleting ? "" : deleteText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                  padding: EdgeInsets.symmetric(vertical: context.rh(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.rr(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
