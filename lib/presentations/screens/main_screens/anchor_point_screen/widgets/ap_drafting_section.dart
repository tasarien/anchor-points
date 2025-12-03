import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:flutter/material.dart';
import '../controllers/anchor_point_controller.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:anchor_point_app/presentations/screens/drafting_screen.dart';
import 'package:provider/provider.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';

class ApDraftingSection extends StatelessWidget {
  final AnchorPointController controller;
  ApDraftingSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<DataProvider>(context);
    final ap = appData.currentAnchorPoint!;

    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    Widget content;

    if (ap.segmentPrompts == null || ap.segmentPrompts!.isEmpty) {
      content = GestureDetector(
        onTap: () {
          if (ap.status == AnchorPointStatus.created) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DraftingScreen(anchorPoint: ap),
              ),
            );
          }
        },
        child: Center(child: Text(getText('no_segments_yet'))),
      );
    } else {
      content = Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: ap.segmentPrompts!
                .map(
                  (segment) => Row(
                    children: [
                      WholeSymbol(
                        symbol: segment.segmentData.symbol,
                        size: const Size(36, 36),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(segment.segmentData.name ?? '')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return Padding(
      key: controller.draftingSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Expanded(child: content)],
      ),
    );
  }
}
