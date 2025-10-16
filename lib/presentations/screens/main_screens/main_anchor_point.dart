import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/create_anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class MainAnchorPointScreen extends StatefulWidget {
  const MainAnchorPointScreen({Key? key}) : super(key: key);

  @override
  State<MainAnchorPointScreen> createState() => _MainAnchorPointScreenState();
}

class _MainAnchorPointScreenState extends State<MainAnchorPointScreen> {
  AnchorPoint? currentAnchorPoint;

  String getText(String text) {
    return AppLocalizations.of(context).translate(text);
  }

  Widget createFirstAPButton() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CreateAnchorPointScreen()),
        );
      },
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: FaIcon(
                      AnchorPointIcons.anchor_point_icon,
                      size: 100,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FaIcon(
                      FontAwesomeIcons.circlePlus,
                      size: 30,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(getText('anchor_point_screen_create_first')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<DataProvider>();

    // Determine wich anchor point to display

    if (appData.getAnchorPoints.isEmpty) {
      currentAnchorPoint = null;
    } else {
      if (appData.userInfo!.pinnedAnchorPointId != null) {
        debugPrint('there');
        currentAnchorPoint = appData.getAnchorPoints.firstWhere(
          (element) => element.id == appData.userInfo!.pinnedAnchorPointId,
        );

        debugPrint(currentAnchorPoint!.name.toString());
      } else {
        currentAnchorPoint = appData.getAnchorPoints.first;
      }
    }

    return Scaffold(
      body: Center(
        child: currentAnchorPoint != null
            ? AnchorPointScreen(anchorPoint: currentAnchorPoint!)
            : createFirstAPButton(),
      ),
    );
  }
}
