import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());
  const backendUrl = String.fromEnvironment('BACKEND_URL');
  final graphQlClient = GraphQLClient(
    link: HttpLink('$backendUrl/graphql'),
    cache: GraphQLCache(),
  );
  final valueNotifier = ValueNotifier<GraphQLClient>(graphQlClient);

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(
      settingsController: settingsController, valueNotifier: valueNotifier));
}
