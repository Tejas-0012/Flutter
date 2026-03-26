import 'package:flutter/material.dart';
import 'game_route.dart';
// import 'home_routes.dart';  // (optional if you make them later)
// import 'profile_routes.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    ...GameRoutes.routes,
    // ...HomeRoutes.routes,
    // ...ProfileRoutes.routes,
  };
}
