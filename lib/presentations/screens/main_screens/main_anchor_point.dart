import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/create_anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/screens/demo_anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen/anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/screens/premium_account_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class MainAnchorPointScreen extends StatefulWidget {
  const MainAnchorPointScreen({Key? key}) : super(key: key);

  @override
  State<MainAnchorPointScreen> createState() => _MainAnchorPointScreenState();
}

class _MainAnchorPointScreenState extends State<MainAnchorPointScreen> {
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

  Widget goToPremiumSelector() {
    DataProvider appData = context.watch<DataProvider>();

    return WholeButton(
      text: getText('change_for_premium'),
      icon: FontAwesomeIcons.arrowUpFromGroundWater,
      wide: true,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PremiumAccountScreen(appData: appData),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<DataProvider>();

    return Scaffold(
      body: Center(
        child: appData.isReloading
            ? LoadingIndicator()
            : appData.currentAPController.currentAnchorPoint != null
            ? AnchorPointScreen(appData: appData)
            : createFirstAPButton(),
      ),
    );
  }
}
