// lib/src/voice/voice_commands.dart
import 'package:flutter/material.dart';
import 'package:platter/src/navigation/main_navigator.dart';
import 'package:platter/src/context/cart_provider.dart';
import 'package:provider/provider.dart';

class VoiceCommands {
  String _currentScreen = 'home';

  void setCurrentScreen(String screen) {
    _currentScreen = screen;
    print('🎯 Voice context set to: $screen');
  }

  bool executeCommand(String command, {BuildContext? context}) {
    final lowerCommand = command.toLowerCase();
    print(
      '🎯 Processing voice command: "$lowerCommand" on screen: $_currentScreen',
    );

    // Try screen-specific commands first
    bool handled = _handleScreenSpecificCommands(lowerCommand, context);
    if (handled) return true;

    // Then try global navigation commands
    if (_handleNavigation(lowerCommand, context)) {
      return true;
    }

    return false;
  }

  bool _handleScreenSpecificCommands(String command, BuildContext? context) {
    switch (_currentScreen) {
      case 'home':
        return _handleHomeCommands(command, context);
      case 'food':
        return _handleFoodCommands(command, context);
      case 'cart':
        return _handleCartCommands(command, context);
      case 'games':
        return _handleGameCommands(command, context);
      default:
        return false;
    }
  }

  bool _handleHomeCommands(String command, BuildContext? context) {
    if (command.contains('feeling') ||
        command.contains('mood') ||
        command.contains("i'm")) {
      final mood = _extractMood(command);
      print('🎯 Setting mood: $mood');
      return true;
    }

    if (command.contains('search for') || command.contains('find restaurant')) {
      final query = _extractSearchQuery(command);
      print('🎯 Searching restaurants: $query');
      return true;
    }

    if (command.contains('weather') || command.contains('climate')) {
      print('🎯 Showing weather recommendations');
      return true;
    }

    return false;
  }

  bool _handleFoodCommands(String command, BuildContext? context) {
    if (command.contains('add') && command.contains('to cart')) {
      final item = _extractItemName(command);
      print('🎯 Adding to cart: $item');
      return true;
    }

    if (command.contains('search') || command.contains('find')) {
      final query = _extractSearchQuery(command);
      print('🎯 Searching menu: $query');
      MainNavigator.switchToTab(1);
      return true;
    }

    if (command.contains('filter by') || command.contains('show me')) {
      final category = _extractCategory(command);
      print('🎯 Filtering by category: $category');
      return true;
    }

    return false;
  }

  bool _handleCartCommands(String command, BuildContext? context) {
    if (context == null) return false;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (command.contains('remove') && command.contains('from cart')) {
      final item = _extractItemName(command);
      print('🎯 Removing from cart: $item');
      return true;
    }

    if (command.contains('checkout') || command.contains('place order')) {
      print('🎯 Proceeding to checkout');
      return true;
    }

    if (command.contains('clear cart') || command.contains('empty cart')) {
      print('🎯 Clearing cart');
      return true;
    }

    if (command.contains('what\'s in my cart') ||
        command.contains('cart items')) {
      print('🎯 Querying cart contents');
      return true;
    }

    return false;
  }

  bool _handleGameCommands(String command, BuildContext? context) {
    if (command.contains('play') || command.contains('start game')) {
      final game = _extractGameName(command);
      print('🎯 Starting game: $game');
      return true;
    }

    if (command.contains('trivia') || command.contains('quiz')) {
      print('🎯 Starting food trivia game');
      return true;
    }

    if (command.contains('spin') || command.contains('wheel')) {
      print('🎯 Starting spin wheel game');
      return true;
    }

    return false;
  }

  bool _handleNavigation(String command, BuildContext? context) {
    try {
      if (command.contains('home') || command == 'home') {
        MainNavigator.switchToTab(0);
        print('✅ Navigated to Home');
        return true;
      } else if (command.contains('food') || command == 'food') {
        MainNavigator.switchToTab(1);
        print('✅ Navigated to Food');
        return true;
      } else if (command.contains('game') || command.contains('games')) {
        MainNavigator.switchToTab(2);
        print('✅ Navigated to Games');
        return true;
      } else if (command.contains('cart') ||
          command == 'cart' ||
          command.contains('card')) {
        MainNavigator.switchToTab(3);
        print('✅ Navigated to Cart');
        return true;
      }
    } catch (e) {
      print('❌ Navigation error: $e');
    }
    return false;
  }

  // Helper methods
  String _extractMood(String text) {
    final moodKeywords = {
      'happy': ['happy', 'celebrating', 'excited', 'good'],
      'lazy': ['lazy', 'tired', 'chill', 'relax'],
      'healthy': ['healthy', 'fit', 'diet', 'light'],
      'comfort': ['comfort', 'cozy', 'warm'],
      'adventurous': ['adventurous', 'try something', 'new'],
    };

    for (final entry in moodKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'normal';
  }

  String _extractSearchQuery(String text) {
    final patterns = [
      RegExp(r'(search for|find)\s+(.+)'),
      RegExp(r'(look for)\s+(.+)'),
      RegExp(r'(show me)\s+(.+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return match.group(2)?.trim() ?? text;
      }
    }
    return text;
  }

  String _extractItemName(String text) {
    final patterns = [
      RegExp(r'(add|remove)\s+(.+?)\s+(from|to)'),
      RegExp(r'(order)\s+(.+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return match.group(2)?.trim() ?? text;
      }
    }
    return text;
  }

  String _extractCategory(String text) {
    final categories = [
      'rice',
      'main course',
      'appetizer',
      'starter',
      'dessert',
      'beverage',
      'drink',
    ];
    for (final category in categories) {
      if (text.contains(category)) {
        return category;
      }
    }
    return 'all';
  }

  String _extractGameName(String text) {
    if (text.contains('trivia') || text.contains('quiz')) return 'trivia';
    if (text.contains('spin') || text.contains('wheel')) return 'spin_wheel';
    if (text.contains('match')) return 'food_match';
    if (text.contains('guess')) return 'guess_dish';
    return 'trivia';
  }

  List<String> getAvailableCommands() {
    return [
      'go to home',
      'go to food',
      'go to games',
      'go to cart',
      'search for [food]',
      'add [item] to cart',
      'remove [item] from cart',
      'checkout',
      'clear cart',
      'how are you feeling?',
      'stop voice',
    ];
  }
}
