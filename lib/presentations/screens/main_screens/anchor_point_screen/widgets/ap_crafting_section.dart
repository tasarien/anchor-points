import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen/widgets/ap_card_template.dart';
import 'package:anchor_point_app/presentations/widgets/ap_request_tile.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/request_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/anchor_point_controller.dart';
import 'package:anchor_point_app/presentations/screens/crafting_screen.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:provider/provider.dart';

class ApCraftingSection extends StatelessWidget {
  final AnchorPointController controller;
  ApCraftingSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    final appData = Provider.of<DataProvider>(context);
    final ap = appData.currentAPController.currentAnchorPoint!;
    final bool available = controller.step2Present;

    final hasRequests = ap.request != null;

    return Padding(
      key: controller.craftingSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ApCardTemplate(
        available: controller.step2Present,
        activeStep: controller.progressController.currentStep == 1,
        step: 2,
        icon: AnchorPointIcons.anchor_point_step2,
        child: hasRequests
            ? RequestListTileNotifications(
                request: controller.currentAnchorPoint!.request!,
                mode: RequestTileMode.forRequester,
                userId: Supabase.instance.client.auth.currentUser!.id,
                expanded:
                    controller.currentAnchorPoint!.status ==
                    AnchorPointStatus.drafted,
              )
            : GestureDetector(
                onTap: () {
                  if (ap.status == AnchorPointStatus.drafted) {
                    appData.changeTabVisibility(false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CraftingScreen(anchorPoint: ap),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(getText('create_request')),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
      ),
    );
  }
}
