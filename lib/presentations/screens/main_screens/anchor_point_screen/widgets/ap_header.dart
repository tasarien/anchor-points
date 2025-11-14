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
    final appData = Provider.of<DataProvider>(context, listen: false);

    return AppBar(
      actions: [
        if (controller.editMode)
          WholeButton(
            onPressed: controller.revertChanges,
            text: 'Cancel',
            suggested: false,
            wide: true,
          ),
        const SizedBox(width: 10),
        if (controller.editMode)
          WholeButton(
            onPressed: () => controller.saveChanges(context),
            icon: FontAwesomeIcons.floppyDisk,
            text: 'Save',
            wide: true,
          ),
        if (!controller.editMode)
          WholePopup(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WholeButton(
                  icon: FontAwesomeIcons.pen,
                  text: 'Edit',
                  onPressed: () {
                    controller.toggleEditMode();
                    Navigator.of(context).pop();
                  },
                ),
                WholeButton(
                  icon: FontAwesomeIcons.trash,
                  text: 'Delete',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('Delete anchor point?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          controller.loading
                              ? const LoadingIndicator()
                              : TextButton(
                                  onPressed: () async {
                                    controller.loading = true;
                                    Navigator.of(context).pop();
                                    await SupabaseAnchorPointSource()
                                        .deleteAnchorPoint(
                                          appData.currentAnchorPoint!.id,
                                        );
                                    controller.loading = false;
                                    await appData.loadOwnedAnchorPoints();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Anchor point deleted'),
                                      ),
                                    );
                                  },
                                  child: const Text('Delete'),
                                ),
                        ],
                      ),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
