import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/presentations/widgets/ap_request_tile.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final ap = appData.currentAnchorPoint!;

    final hasRequests = ap.textRequest != null || ap.audioRequest != null;

    return Padding(
      key: controller.craftingSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: hasRequests
              ? Column(
                  children: [
                    RequestListTile(request: ap.textRequest!),
                    RequestListTile(request: ap.audioRequest!),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    if (ap.status == AnchorPointStatus.drafted) {
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
                      Text('Create requests'),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
