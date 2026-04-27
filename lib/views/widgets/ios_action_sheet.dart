import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:manager/core/extensions/l10n_extension.dart';
import 'package:manager/views/widgets/alerts/top_alert.dart';
import 'package:manager/views/widgets/app_snackbar.dart';
import 'package:manager/views/widgets/custom_popup.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

Future<void> showIosActionSheet({
  required BuildContext context,
  required String name,
  required VoidCallback onDetail,
  required Future<bool> Function() onDelete,
  required VoidCallback onEdit,
}) async {
  final parentContext = context;

  FocusManager.instance.primaryFocus?.unfocus();

  showCupertinoModalPopup(
    context: parentContext,
    builder: (sheetContext) => CupertinoActionSheet(
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(sheetContext);
            onDetail();
          },
          child: Text(
            parentContext.l10n.common_detail,
            // style: TextStyle(color: Colors.yellow),
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(sheetContext);
            onEdit();
          },
          child: Text(parentContext.l10n.common_edit),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(sheetContext);
            await Future.delayed(const Duration(milliseconds: 150));
            await showPopup(
              context: parentContext,
              type: AlertType.warning,
              title: parentContext.l10n.common_warning,
              content: parentContext.l10n.confirmDeleteItem(name.toLowerCase()),
              onCancelPressed: () {},
              onOkPressed: () async {
                final success = await onDelete();

                if (success) {
                  TopAlert.success(
                    parentContext,
                    parentContext.l10n.action_success(
                      parentContext.l10n.common_delete,
                      name.toLowerCase(),
                    ),
                  );
                } else {
                  TopAlert.error(
                    parentContext,
                    parentContext.l10n.action_failed(
                      parentContext.l10n.common_delete,
                      name.toLowerCase(),
                    ),
                  );
                }
              },
            );
          },
          child: Text(parentContext.l10n.common_delete),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(sheetContext),
        child: Text(parentContext.l10n.common_cancel),
      ),
    ),
  );
}
