import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes.dart';
import 'services/auth_service.dart';
import 'services/trips_service.dart';


class TropicaGuideApp extends StatelessWidget {
  const TropicaGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Central place to provide your app services.
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<TripsService>(create: (_) => TripsService()),
      ],
      child: MaterialApp(
        title: 'TropicaGuide',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        initialRoute: Routes.authGate,
        routes: buildRoutes(),
      ),
    );
  }
}
