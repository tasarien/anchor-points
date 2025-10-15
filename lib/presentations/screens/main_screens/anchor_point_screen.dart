import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/create_anchor_point_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class AnchorPointScreen extends StatelessWidget {
  const AnchorPointScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DataProvider appData = context.watch<DataProvider>();

    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    Widget createFirstAPButton() {
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
                      child: FaIcon(FontAwesomeIcons.circlePlus, size: 30),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Anchor Point')),
      body: SingleChildScrollView(
        child: Center(
          child: appData.getAnchorPoints.isNotEmpty
              ? appData.getAnchorPoints.first.buildAPWidget()
              : createFirstAPButton(),
        ),
      ),
    );
  }
}
