import 'package:flutter/material.dart';
import 'package:mado_flutter/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mado_flutter/src/ws_set/ws_set_list_view.dart';
import 'package:mado_flutter/src/ws_set/ws_card_list_view.dart';
import 'package:mado_flutter/src/ws_set/ws_card_detail_view.dart';

import 'sample_feature/sample_item_details_view.dart';
import 'sample_feature/sample_item_list_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
    required this.valueNotifier,
  });

  final SettingsController settingsController;
  final ValueNotifier<GraphQLClient> valueNotifier;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return GraphQLProvider(
            client: valueNotifier,
            child: MaterialApp(
              // Providing a restorationScopeId allows the Navigator built by the
              // MaterialApp to restore the navigation stack when a user leaves and
              // returns to the app after it has been killed while running in the
              // background.
              restorationScopeId: 'app',

              // Provide the generated AppLocalizations to the MaterialApp. This
              // allows descendant Widgets to display the correct translations
              // depending on the user's locale.
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''), // English, no country code
              ],

              // Use AppLocalizations to configure the correct application title
              // depending on the user's locale.
              //
              // The appTitle is defined in .arb files found in the localization
              // directory.
              onGenerateTitle: (BuildContext context) =>
                  AppLocalizations.of(context)!.appTitle,

              // Define a light and dark color theme. Then, read the user's
              // preferred ThemeMode (light, dark, or system default) from the
              // SettingsController to display the correct theme.
              theme: ThemeData(),
              darkTheme: ThemeData.dark(),
              themeMode: settingsController.themeMode,

              // Define a function to handle named routes in order to support
              // Flutter web url navigation and deep linking.
              onGenerateRoute: (RouteSettings routeSettings) {
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (BuildContext context) {
                    final name = routeSettings.name;
                    if (name == SettingsView.routeName) {
                      return SettingsView(controller: settingsController);
                    }
                    if (name == SampleItemDetailsView.routeName) {
                      return const SampleItemDetailsView();
                    }
                    if (name?.startsWith('/set/') ?? false) {
                      final rest = name!.substring('/set/'.length);
                      final cardMarker = rest.indexOf('/card/');
                      if (cardMarker != -1) {
                        final setCode = rest.substring(0, cardMarker);
                        final idCard = Uri.decodeComponent(
                            rest.substring(cardMarker + '/card/'.length));
                        return WsCardDetailRoute(
                            idCard: idCard, setCode: setCode);
                      }
                      final setCode = rest;
                      final args =
                          routeSettings.arguments as Map<String, String>?;
                      final title = args?['title'] ?? setCode;
                      return Scaffold(
                        appBar: AppBar(title: Text(title)),
                        body: WsCardListView(setCode: setCode),
                      );
                    }
                    return Scaffold(
                      appBar: AppBar(title: const Text('Sets')),
                      body: const WsSetListView(),
                    );
                  },
                );
              },
            ));
      },
    );
  }
}
