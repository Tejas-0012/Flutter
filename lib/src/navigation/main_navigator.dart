import 'package:flutter/material.dart';
import 'package:platter/src/navigation/stacks/game_stack.dart';
import 'package:platter/src/navigation/stacks/home_stack.dart';
import "../screens/food_screen.dart";
import '../screens/cart_screen.dart';
import '../screens/speak_screen.dart';
import '../components/top_navigation_bar.dart'; // custom widget
import 'custom_drawer_content.dart'; // custom drawer UI

final GlobalKey<_MainNavigatorState> mainNavigatorKey =
    GlobalKey<_MainNavigatorState>();

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();

  static void switchToTab(int index) {
    mainNavigatorKey.currentState?.switchToTab(index);
  }
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  int cartItemsCount = 3;

  final List<Widget> _screens = [
    const HomeStack(),
    const FoodScreen(), // This should be the Food tab
    const SpeakScreen(),
    const GameStack(),
    const CartScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 Drawer Section
      drawer: const CustomDrawerContent(),

      // 🔹 AppBar (TopNavigationBar equivalent)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopNavigationBar(
          onSearch: (text) => debugPrint('Search: $text'),
          onProfilePress: () {
            Navigator.pop(context); // close drawer if open
            // Don't change _selectedIndex here - let the drawer handle navigation
          },
          onCartPress: () {
            setState(() => _selectedIndex = 4); // Cart is at index 4
          },
          cartItemsCount: cartItemsCount,
        ),
      ),

      // 🔹 Screen content
      body: _screens[_selectedIndex],

      // 🔹 Bottom Navigation Tabs
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Food'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Speak'),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
