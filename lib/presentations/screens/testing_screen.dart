import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/presentations/providers/settings_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/info_box.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/section_tab.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_popup.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_scaffold_body.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Testing Screen - only for UI testing and debugging purposes

class TestingScreen extends StatefulWidget {
  const TestingScreen({Key? key}) : super(key: key);

  @override
  _TestingScreenState createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  String getText(text) {
    return AppLocalizations.of(context).translate(text);
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(getText("testing_screen_title"))),
      body: WholeScaffoldBody(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 10,
            children: [
              DropdownButton<String>(
                value: settings.locale.languageCode,
                onChanged: (lang) {
                  if (lang != null) settings.changeLanguage(lang);
                },
                items: AppLocalizations.supportedLocales
                    .map(
                      (locale) => DropdownMenuItem(
                        value: locale.languageCode,
                        child: Text(
                          AppLocalizations.getLocaleName(locale.languageCode),
                        ),
                      ),
                    )
                    .toList(),
              ),

              WholeButton(
                icon: settings.isDarkMode
                    ? FontAwesomeIcons.moon
                    : FontAwesomeIcons.sun,
                text: settings.isDarkMode
                    ? getText('dark_mode')
                    : getText('light_mode'),
                onPressed: () {
                  settings.toggleDarkMode();
                },
              ),
              Slider(value: 0.2, onChanged: (value) {}),
              SectionTab(text: "Section", content: Text("Section content")),
              InfoBox(text: ["Info 1 ", "Info 2"]),
              WholePopup(content: Text("POP"), child: LoadingIndicator()),
              Row(
                spacing: 10,
                children: [
                  WholePopup(
                    content: Text("POP"),
                    child: WholeButton(
                      icon: FontAwesomeIcons.atlassian,
                      switchMode: false,
                      text: "suggested",
                      suggested: true,
                      onPressed: null,
                    ),
                  ),
                  WholeButton(
                    icon: FontAwesomeIcons.atlassian,
                    text: "not suggested",
                    suggested: false,
                  ),
                  WholeButton(
                    icon: FontAwesomeIcons.atlassian,
                    text: "disabled but unarmed",
                    disabled: true,
                  ),
                  WholeButton(
                    icon: FontAwesomeIcons.atlassian,
                    text: "disabled but unarmed",
                    switchMode: true,
                  ),
                ],
              ),
              WholeButton(dot: true),
              WholeButton(
                wide: true,
                text: "Wide",
                icon: FontAwesomeIcons.wifi,
              ),
              WholeButton(
                wide: true,
                text: "Wide",
                icon: FontAwesomeIcons.wifi,
                suggested: false,
              ),
              WholeButton(
                wide: true,
                text: "Wide",
                icon: FontAwesomeIcons.wifi,
                disabled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
