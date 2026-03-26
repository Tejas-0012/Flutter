import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';
import '../../screens/selected_restaurant_screen.dart';
import '../../screens/cart_screen.dart';

class HomeStack extends StatelessWidget {
  const HomeStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/home',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/restaurant':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) =>
                  SelectedRestaurantScreen(restaurant: args['restaurant']),
            );
          case '/cart':
            return MaterialPageRoute(builder: (_) => const CartScreen());
        }
        return null;
      },
    );
  }
}
