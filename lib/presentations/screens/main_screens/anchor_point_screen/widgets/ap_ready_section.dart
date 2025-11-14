import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/anchor_point_controller.dart';

class ApReadySection extends StatelessWidget {
  final AnchorPointController controller;

  ApReadySection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Padding(
      key: controller.readySectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: WholeButton(
            icon: FontAwesomeIcons.play,
            text: getText('listen_anchor_point'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlayerScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}
