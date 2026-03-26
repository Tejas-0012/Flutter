import 'package:flutter/material.dart';
import 'main_navigator.dart';


class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(color: Colors.black, child: MainNavigator(key: mainNavigatorKey)),
    );
  }
}
