import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:step_progress/step_progress.dart';
import '../controllers/anchor_point_controller.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';

class ApProgressCard extends StatelessWidget {
  final AnchorPointController controller;
  const ApProgressCard({Key? key, required this.controller}) : super(key: key);

  String getText(BuildContext context, String key) =>
      AppLocalizations.of(context).translate(key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 600),
            crossFadeState: controller.progressCardOpened
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: GestureDetector(
              onTap: () {
                controller.changeProgressCardState(true);
              },
              child: Stack(
                children: [
                  if (controller.step1Present)
                    FaIcon(AnchorPointIcons.anchor_point_step1),
                  if (controller.step2Present)
                    FaIcon(AnchorPointIcons.anchor_point_step2),
                  if (controller.step3Present)
                    FaIcon(AnchorPointIcons.anchor_point_step3),
                ],
              ),
            ),
            secondChild: GestureDetector(
              onTap: () {
                controller.changeProgressCardState(false);
              },
              child: Column(
                children: [
                  StepProgress(
                    totalSteps: 3,
                    controller: controller.progressController,
                    width: 240,
                    stepNodeSize: 55,
                    theme: StepProgressThemeData(
                      stepNodeStyle: StepNodeStyle(
                        activeForegroundColor: Colors.transparent,
                        defaultForegroundColor: Colors.transparent,
                      ),
                      stepAnimationDuration: const Duration(milliseconds: 300),
                      defaultForegroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      activeForegroundColor: colorScheme.tertiary,
                    ),
                    nodeLabelBuilder: (index, completed) {
                      final labels = [
                        getText(context, 'ap_status_1'),
                        getText(context, 'ap_status_2'),
                        getText(context, 'ap_status_3'),
                      ];
                      return Text(
                        labels[index],
                        style: TextStyle(
                          color: index > completed
                              ? colorScheme.tertiary
                              : colorScheme.onSurface,
                        ),
                      );
                    },
                    nodeIconBuilder: (index, completed) {
                      final icons = [
                        WholeButton(
                          icon: AnchorPointIcons.anchor_point_step1,
                          suggested: controller.step1Present,
                          onPressed: () {
                            controller.scrollTo(controller.draftingSectionKey);
                          },
                        ),
                        WholeButton(
                          icon: AnchorPointIcons.anchor_point_step2,
                          suggested: controller.step2Present,
                          onPressed: () {
                            controller.scrollTo(controller.craftingSectionKey);
                          },
                        ),
                        WholeButton(
                          icon: AnchorPointIcons.anchor_point_step3,
                          suggested: controller.step3Present,
                          onPressed: () {
                            controller.scrollTo(controller.readySectionKey);
                          },
                        ),
                      ];
                      return SizedBox(
                        height: 80,
                        child: Center(child: icons[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
