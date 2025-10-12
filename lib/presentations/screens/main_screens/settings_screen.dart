import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/presentations/providers/settings_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/section_tab.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as StateProvider;

// Settings Screen - COULD BE IN A SEPARATE FILE

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String getText(text) {
    return AppLocalizations.of(context).translate(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText("settings_screen_title"))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSettingsButton(
                context: context,
                title: getText("settings_account_tab_title"),
                subtitle: getText("settings_account_tab_description"),
                icon: FontAwesomeIcons.user,
                onTap: () => _navigateToAccountSettings(context),
              ),
              const SizedBox(height: 16),
              _buildSettingsButton(
                context: context,
                title: getText("settings_display_tab_title"),
                subtitle: getText("settings_display_tab_description"),
                icon: FontAwesomeIcons.sliders,
                onTap: () => _navigateToToneAdjustment(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: colorScheme.surface, size: 24),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.onSurface,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _navigateToAccountSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
    );
  }

  void _navigateToToneAdjustment(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => DisplayAdjustmentScreen()));
  }
}

// Account Settings Screen
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Scaffold(
      appBar: AppBar(title: Text(getText("settings_account_tab_title"))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    spacing: 20,
                    children: [
                      SectionTab(
                        text: getText("settings_account_actions_tab_title"),
                      ),
                      WholeButton(
                        onPressed: () => _handleSignOut(context),
                        wide: true,
                        text: getText("settings_logout_button"),
                        icon: FontAwesomeIcons.arrowRightFromBracket,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tone Adjustment Screen
class DisplayAdjustmentScreen extends StatefulWidget {
  const DisplayAdjustmentScreen({super.key});

  @override
  _DisplayAdjustmentScreenState createState() =>
      _DisplayAdjustmentScreenState();
}

class _DisplayAdjustmentScreenState extends State<DisplayAdjustmentScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    SettingsProvider settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(getText("settings_display_tab_title"))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SectionTab(
                        text: getText("settings_display_tab_language_title"),
                      ),
                      const SizedBox(height: 20),
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
                                  AppLocalizations.getLocaleName(
                                    locale.languageCode,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SectionTab(
                        text: getText("settings_display_tab_color_title"),
                      ),
                      const SizedBox(height: 20),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
