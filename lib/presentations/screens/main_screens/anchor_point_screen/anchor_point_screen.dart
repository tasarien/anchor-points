import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen/widgets/ap_title_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/anchor_point_controller.dart';
import 'widgets/ap_header.dart';
import 'widgets/ap_progress_card.dart';
import 'widgets/ap_drafting_section.dart';
import 'widgets/ap_crafting_section.dart';
import 'widgets/ap_ready_section.dart';
import 'widgets/ap_description_section.dart';
import 'widgets/ap_archived_section.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';

class AnchorPointScreen extends StatelessWidget {
  final DataProvider appData;
  const AnchorPointScreen({Key? key, required this.appData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnchorPointController(appData),
      child: Consumer<AnchorPointController>(
        builder: (context, controller, _) => Scaffold(
          appBar: ApHeader(controller: controller),
          body: controller.saveLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    SingleChildScrollView(
                      controller: controller.scrollController,
                      child: Column(
                        children: [
                          ApProgressCard(controller: controller),
                          ApTitleSection(controller: controller),
                          if (controller.statusArchived)
                            const ApArchivedSection(),
                          if (controller.step3Present)
                            ApReadySection(controller: controller),
                          if (controller.step2Present)
                            ApCraftingSection(controller: controller),
                          if (controller.step1Present)
                            ApDraftingSection(controller: controller),
                          ApDescriptionSection(controller: controller),
                        ],
                      ),
                    ),
                    if (!controller.isAtBottom)
                      const Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Icon(Icons.keyboard_arrow_down),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
