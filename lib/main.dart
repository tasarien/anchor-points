import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/localizations/app_localizations_delegate.dart';
import 'package:anchor_point_app/presentations/providers/auth_provider.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/providers/settings_provider.dart';
import 'package:anchor_point_app/presentations/screens/auth_screen.dart';
import 'package:anchor_point_app/presentations/screens/loading_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screen.dart';
import 'package:anchor_point_app/presentations/screens/set_up_screen.dart';
import 'package:anchor_point_app/presentations/screens/testing_screen.dart';
import 'package:anchor_point_app/presentations/theme/app_theme.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init of supabase
  await Supabase.initialize(
    url: 'https://lmsrhlknxtcwowxslqag.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtc3JobGtueHRjd293eHNscWFnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDE5OTg3NCwiZXhwIjoyMDU5Nzc1ODc0fQ.hvJvwpaDvwv7pUMCO6SNQj8XiehdlnPOGkgvQxWFqjY',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(supabase)),
        ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
          create: (_) => DataProvider(),
          update: (_, auth, dataProvider) {
            final user = auth.user;

            if (user == null) {
              dataProvider?.clearData();
            } else {
              dataProvider?.clearData();
              dataProvider?.loadAllData();
            }

            return dataProvider!;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Anchor Points',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            //theme: AppTheme.lightTheme,
            theme: AppTheme.darkTheme,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: StreamBuilder<AuthState>(
              stream: supabase.auth.onAuthStateChange,
              builder: (context, snapshot) {
                final session = snapshot.data?.session;

                if (session != null) {
                  return LoadingScreen();
                } else {
                  return AuthScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
