import 'package:flutter/material.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';

class ApArchivedSection extends StatelessWidget {
  const ApArchivedSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
    return AppLocalizations.of(context).translate(text);
  }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(getText('archived')),
        ),
      ),
    );
  }
}
