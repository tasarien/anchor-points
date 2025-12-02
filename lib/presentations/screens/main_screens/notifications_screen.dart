import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Scaffold(
      appBar: AppBar(title: Text(getText('notifications'))),
      body: Center(
        child: Text(getText("no_notifications_yet"), style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
