import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import '../controllers/anchor_point_controller.dart';
import 'package:anchor_point_app/presentations/widgets/drawers/image_picker.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';

class ApTitleSection extends StatelessWidget {
  final AnchorPointController controller;

  const ApTitleSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final getText = (String key) => AppLocalizations.of(context).translate(key);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          width: 300,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(30),
                child: Card(child: Container(width: 270, height: 270)),
              ),

              // --- IMAGE ---
              ClipOval(
                child: controller.imageUrl != null
                    ? Image.network(
                        controller.imageUrl!,
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/empty_landscape.png',
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
              ),

              // --- EDIT IMAGE BUTTON ---
              if (controller.editMode)
                Positioned(
                  top: 0,
                  right: 0,
                  child: WholeButton(
                    onPressed: () async {
                      final url = await showSupabaseImagePickerModal(context);
                      if (url != null) controller.setImageUrl(url);
                    },
                    icon: FontAwesomeIcons.pen,
                    text: getText('edit_image'),
                  ),
                ),

              // --- TITLE FIELD ---
              Transform.translate(
                offset: const Offset(0, 100),
                child: SizedBox(
                  width: 220,
                  child: TextField(
                    controller: controller.titleController,
                    textAlign: TextAlign.center,
                    readOnly: !controller.editMode,
                    enableInteractiveSelection: controller.editMode,
                    maxLength: controller.editMode ? 24 : null,
                    decoration: InputDecoration(
                      fillColor: colorScheme.surface,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: controller.editMode
                              ? colorScheme.error
                              : colorScheme.tertiary,
                          width: controller.editMode ? 2 : 1,
                        ),
                      ),
                      focusColor: controller.editMode
                          ? colorScheme.error
                          : colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
