import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/trips/my_trips_screen.dart';
import 'screens/trips/trip_form_screen.dart';
import 'screens/trip_detail/trip_detail_screen.dart';
import 'screens/activity_search/activity_search_screen.dart';

class Routes {
  static const authGate = '/';
  static const login = '/login';
  static const register = '/register';
  static const myTrips = '/my-trips';
  static const tripForm = '/trip-form';
  static const tripDetail = '/trip-detail';
  static const activitySearch = '/activity-search';
}

Map<String, WidgetBuilder> buildRoutes() {
  return {
    Routes.authGate: (_) => const AuthGate(),
    Routes.login: (_) => const LoginScreen(),
    Routes.register: (_) => const RegisterScreen(),
    Routes.myTrips: (_) => const MyTripsScreen(),
    // These routes require arguments, so we’ll navigate via MaterialPageRoute for them.
  };
}
