import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/final_ap_segment.dart';
import 'package:anchor_point_app/data/models/segment_data.dart';
import 'package:anchor_point_app/data/models/segment_prompt_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen/widgets/ap_card_template.dart';
import 'package:anchor_point_app/presentations/screens/player_screen/player_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/anchor_point_controller.dart';

class ApReadySection extends StatelessWidget {
  final AnchorPoint anchorPoint;
  final AnchorPointController controller;

  ApReadySection({
    Key? key,
    required this.anchorPoint,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    final DataProvider appData = context.watch<DataProvider>();
    final bool available = controller.step3Present;

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: controller.readySectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: ApCardTemplate(
        available: available,
        activeStep: controller.progressController.currentStep == 2,
        step: 3,
        icon: AnchorPointIcons.anchor_point_step3,
        child: Container(
          width: double.infinity,
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(width: 50, height: 1, color: colorScheme.secondary),
              WholeButton(
                icon: FontAwesomeIcons.play,
                text: getText('listen_anchor_point'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(
                        anchorPoint: anchorPoint,
                        appData: appData,
                      ),
                    ),
                  );
                },
              ),
              Container(width: 50, height: 1, color: colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
