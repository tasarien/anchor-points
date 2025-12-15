import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/anchor_point_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_popup.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator%20copy.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';

class ApHeader extends StatelessWidget implements PreferredSizeWidget {
  final AnchorPointController controller;
  const ApHeader({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    DataProvider appData = context.watch<DataProvider>();

    return AppBar(
      actions: [
        // Show Cancel and Save buttons when in edit mode
        if (controller.editMode) ...[
          WholeButton(
            onPressed: controller.revertChanges,
            text: getText('cancel'),
            suggested: false,
            wide: true,
          ),
          const SizedBox(width: 10),
          controller.saveLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: LoadingIndicator(),
                )
              : WholeButton(
                  onPressed: () => _handleSave(context, controller, appData),
                  icon: FontAwesomeIcons.floppyDisk,
                  text: getText('save'),
                  wide: true,
                ),
          const SizedBox(width: 10),
        ],

        // Show menu popup when NOT in edit mode
        if (!controller.editMode && !controller.statusArchived)
          WholePopup(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WholeButton(
                  icon: FontAwesomeIcons.pen,
                  text: getText('edit'),
                  onPressed: () {
                    controller.toggleEditMode();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 10),
                WholeButton(
                  icon: FontAwesomeIcons.trash,
                  text: getText('delete'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmation(
                      context,
                      controller,
                      appData,
                      getText,
                    );
                  },
                ),
              ],
            ),
            child: const SizedBox(
              width: 60,
              height: 60,
              child: Icon(Icons.more_vert),
            ),
          ),
      ],
    );
  }

  /// Handles saving changes
  Future<void> _handleSave(
    BuildContext context,
    AnchorPointController controller,
    DataProvider appData,
  ) async {
    try {
      await controller.saveChanges(context);

      // Refresh the anchor point in the provider's list
      if (controller.currentAnchorPoint != null) {
        await appData.refreshAnchorPoint(controller.currentAnchorPoint!.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('changes_saved'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('save_failed'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows delete confirmation dialog
  void _showDeleteConfirmation(
    BuildContext context,
    AnchorPointController controller,
    DataProvider appData,
    String Function(String) getText,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(getText('delete_anchor_point')),
        content: Text(getText('delete_anchor_point_question')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(getText('cancel')),
          ),
          TextButton(
            onPressed: () => _handleDelete(
              context,
              dialogContext,
              controller,
              appData,
              getText,
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(getText('sure_delete')),
          ),
        ],
      ),
    );
  }

  /// Handles anchor point deletion
  Future<void> _handleDelete(
    BuildContext context,
    BuildContext dialogContext,
    AnchorPointController controller,
    DataProvider appData,
    String Function(String) getText,
  ) async {
    if (controller.currentAnchorPoint == null) return;

    // Close dialog first
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(getText('deleting')),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      final anchorPointId = controller.currentAnchorPoint!.id;

      // Delete from backend
      await SupabaseAnchorPointSource().deleteAnchorPoint(anchorPointId);

      // Reload data
      await appData.loadOwnedAnchorPoints();
      await appData.pickFirstAnchorPoint();
      appData.tabController.jumpToTab(1);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('anchor_point_deleted')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting anchor point: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('delete_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
