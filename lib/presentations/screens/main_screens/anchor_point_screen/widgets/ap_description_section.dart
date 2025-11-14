import 'package:flutter/material.dart';
import '../controllers/anchor_point_controller.dart';

class ApDescriptionSection extends StatelessWidget {
  final AnchorPointController controller;
  const ApDescriptionSection({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: controller.descriptionController,
            textAlign: TextAlign.center,
            readOnly: !controller.editMode,
            minLines: 1,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: controller.descriptionController.text.isEmpty
                  ? 'No description provided'
                  : null,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: controller.editMode ? scheme.error : scheme.tertiary,
                  width: controller.editMode ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
