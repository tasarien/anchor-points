import 'package:anchor_point_app/core/constants/appSetup.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/create_anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/info_box.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class OtherAPScreen extends StatelessWidget {
  const OtherAPScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DataProvider appData = context.watch<DataProvider>();
    bool limitReached = appData.anchorPoints.length == appSetup['ap_limit'];

    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Scaffold(
      appBar: AppBar(title: Text(getText("other_ap_screen_title"))),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: appData.anchorPoints.length,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemBuilder: (context, index) {
                AnchorPoint anchorPoint = appData.anchorPoints[index];
                return anchorPoint.buildAPWidgetSmall();
              },
            ),
          ),
          if (limitReached)
            InfoBox(text: [getText('other_ap_screen_limit_reached')]),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: WholeButton(
              text: getText('other_ap_screen_add_anchor_point'),
              icon: FontAwesomeIcons.circlePlus,
              wide: true,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAnchorPointScreen(),
                  ),
                );
              },
              disabled: limitReached,
            ),
          ),
        ],
      ),
    );
  }
}
