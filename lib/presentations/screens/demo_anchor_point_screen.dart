import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';

class DemoAnchorPointScreen extends StatelessWidget {
  final DataProvider appData;
  const DemoAnchorPointScreen({Key? key, required this.appData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }
    return Container(
      child: Text(getText('demo_anchor_point')),
    );
  }
}
