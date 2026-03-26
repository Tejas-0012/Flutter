// lib/src/utils/voice_command_processor.dart
import '../models/restaurant.dart';

class VoiceCommandProcessor {
  static List<Restaurant> availableRestaurants = []; // Add this line

  static Map<String, dynamic> processCommand(
    String command,
    String currentScreen, {
    List<Restaurant>? restaurants, // Add optional restaurants parameter
  }) {
    final text = command.toLowerCase().trim();

    // ✅ HANDLE SINGLE-WORD NAVIGATION COMMANDS FIRST
    if (text == 'home' || text == 'go home') {
      return {'command': 'navigate', 'data': 'home'};
    }
    if (text == 'cart' || text == 'go cart' || text == 'show cart') {
      return {'command': 'navigate', 'data': 'cart'};
    }
    if (text == 'food' || text == 'go food' || text == 'show food') {
      return {'command': 'navigate', 'data': 'food'};
    }
    if (text == 'games' ||
        text == 'game' ||
        text == 'go games' ||
        text == 'play games') {
      return {'command': 'navigate', 'data': 'games'};
    }
    if (text == 'speak' ||
        text == 'voice' ||
        text == 'go speak' ||
        text == 'voice command') {
      return {'command': 'navigate', 'data': 'speak'};
    }

    // ✅ CHECK FOR SPECIFIC RESTAURANT NAMES FIRST
    if (restaurants != null && restaurants.isNotEmpty) {
      final restaurantCommand = _processRestaurantSpecificCommand(
        text,
        restaurants,
      );
      if (restaurantCommand['command'] != 'unknown') {
        return restaurantCommand;
      }
    }

    // Then process screen-specific commands
    switch (currentScreen) {
      case 'home':
        return _processHomeCommands(text, restaurants);
      case 'menu':
        return _processMenuCommands(text);
      case 'cart':
        return _processCartCommands(text);
      default:
        return _processGlobalCommands(text, restaurants);
    }
  }

  static Map<String, dynamic> _processHomeCommands(
    String text,
    List<Restaurant>? restaurants,
  ) {
    // Mood commands
    if (text.contains('feeling') ||
        text.contains('mood') ||
        text.contains('i\'m')) {
      final mood = _extractMood(text);
      return {'command': 'set_mood', 'data': mood};
    }

    // Search restaurants
    if (text.contains('search for') || text.contains('find')) {
      final query = _extractSearchQuery(text);
      return {'command': 'search_restaurants', 'data': query};
    }

    // Navigation
    if (text.contains('go to') ||
        text.contains('open') ||
        text.contains('show')) {
      final destination = _extractNavigation(text);
      return {'command': 'navigate', 'data': destination};
    }

    return {'command': 'unknown', 'data': text};
  }

  static Map<String, dynamic> _processMenuCommands(String text) {
    if (text.contains('go to cart') ||
        text.contains('show cart') ||
        text.contains('open cart')) {
      return {'command': 'navigate', 'data': 'cart'};
    }

    if (text.contains('go back') ||
        text.contains('back') ||
        text.contains('previous')) {
      return {'command': 'navigate', 'data': 'back'};
    }
    // Add to cart
    if (text.contains('add') && text.contains('to cart')) {
      final item = _extractItemName(text);
      return {'command': 'add_to_cart', 'data': item};
    }

    // Search menu
    if (text.contains('search') || text.contains('find')) {
      final query = _extractSearchQuery(text);
      return {'command': 'search_menu', 'data': query};
    }

    // Filter by category
    if (text.contains('filter by') || text.contains('show me')) {
      final category = _extractCategory(text);
      return {'command': 'filter_menu', 'data': category};
    }

    return {'command': 'unknown', 'data': text};
  }

  static Map<String, dynamic> _processCartCommands(String text) {
    // Remove items
    if (text.contains('remove') && text.contains('from cart')) {
      final item = _extractItemName(text);
      return {'command': 'remove_from_cart', 'data': item};
    }
    if ((text.contains('increase') || text.contains('more')) &&
        (text.contains('quantity') || text.contains('item'))) {
      final item = _extractItemName(text);
      return {'command': 'increase_quantity', 'data': item};
    }

    // Decrease quantity
    if ((text.contains('decrease') ||
            text.contains('less') ||
            text.contains('reduce')) &&
        (text.contains('quantity') || text.contains('item'))) {
      final item = _extractItemName(text);
      return {'command': 'decrease_quantity', 'data': item};
    }

    // Checkout
    if (text.contains('check out') || text.contains('place order')) {
      return {'command': 'checkout', 'data': null};
    }

    // Clear cart
    if (text.contains('clear cart') || text.contains('empty cart')) {
      return {'command': 'clear_cart', 'data': null};
    }

    // Query cart
    if (text.contains('what\'s in my cart') ||
        text.contains('cart items') ||
        text.contains('show my cart') ||
        text.contains('show my card')) {
      return {'command': 'query_cart', 'data': null};
    }

    // Total amount
    if (text.contains('total amount') ||
        text.contains('total price') ||
        text.contains('how much')) {
      return {'command': 'total_amount', 'data': null};
    }

    // Delivery information
    if (text.contains('delivery info') ||
        text.contains('delivery fee') ||
        text.contains('delivery cost')) {
      return {'command': 'delivery_info', 'data': null};
    }

    // Help
    if (text.contains('help') || text.contains('what can i say')) {
      return {'command': 'help', 'data': null};
    }

    return {'command': 'unknown', 'data': text};
  }

  static Map<String, dynamic> _processGlobalCommands(
    String text,
    List<Restaurant>? restaurants,
  ) {
    // Navigation commands that work everywhere
    if (text.contains('home') || text == 'main') {
      return {'command': 'navigate', 'data': 'home'};
    }

    if (text.contains('cart') || text.contains('basket')) {
      return {'command': 'navigate', 'data': 'cart'};
    }

    if (text.contains('food') ||
        text.contains('menu') ||
        text.contains('restaurant')) {
      return {'command': 'navigate', 'data': 'food'};
    }

    if (text.contains('speak') ||
        text.contains('voice') ||
        text.contains('mic')) {
      return {'command': 'navigate', 'data': 'speak'};
    }

    if (text.contains('game') ||
        text.contains('play') ||
        text.contains('fun')) {
      return {'command': 'navigate', 'data': 'games'};
    }
    // 🆕 PAYMENT COMMANDS
    if (text.contains('pay now') ||
        text.contains('make payment') ||
        text.contains('confirm payment')) {
      return {'command': 'make_payment', 'data': null};
    }

    if (text.contains('cancel payment') ||
        text.contains('cancel order') ||
        text.contains('go back')) {
      return {'command': 'cancel_payment', 'data': null};
    }

    if (text.contains('scan qr') ||
        text.contains('qr code') ||
        text.contains('upi payment')) {
      return {'command': 'scan_qr', 'data': null};
    }

    if (text.contains('google pay') || text.contains('gpay')) {
      return {'command': 'google_pay', 'data': null};
    }

    if (text.contains('card payment') ||
        text.contains('credit card') ||
        text.contains('debit card')) {
      return {'command': 'card_payment', 'data': null};
    }

    if (text.contains('cash on delivery') ||
        text.contains('cash delivery') ||
        text.contains('pay cash')) {
      return {'command': 'cash_delivery', 'data': null};
    }

    // Help
    if (text.contains('help') || text.contains('what can i say')) {
      return {'command': 'show_help', 'data': null};
    }

    return {'command': 'unknown', 'data': text};
  }

  // ✅ NEW: Process restaurant-specific commands
  static Map<String, dynamic> _processRestaurantSpecificCommand(
    String text,
    List<Restaurant> restaurants,
  ) {
    // Check for exact restaurant name matches
    for (final restaurant in restaurants) {
      final restaurantName = restaurant.name.toLowerCase();

      // Exact match or contains restaurant name
      if (text == restaurantName ||
          text.contains(restaurantName) ||
          text.contains('go to $restaurantName') ||
          text.contains('open $restaurantName') ||
          text.contains('show $restaurantName')) {
        return {'command': 'open_restaurant', 'data': restaurant};
      }
    }

    // Check for common restaurant abbreviations
    final restaurantAbbreviations = {
      'mavalli tiffin room': ['mtr', 'mavalli', 'tiffin room'],
      'mtr': ['mtr'],
    };

    for (final entry in restaurantAbbreviations.entries) {
      for (final abbreviation in entry.value) {
        if (text.contains(abbreviation)) {
          // Find the actual restaurant in the list
          final matchingRestaurant = restaurants.firstWhere(
            (r) => r.name.toLowerCase().contains(entry.key),
            orElse: () => Restaurant.empty(),
          );
          if (matchingRestaurant.name.isNotEmpty) {
            return {'command': 'open_restaurant', 'data': matchingRestaurant};
          }
        }
      }
    }

    return {'command': 'unknown', 'data': text};
  }

  // Helper methods
  static String _extractSearchQuery(String text) {
    final regex = RegExp(r'(search for|find)\s+(.+)');
    final match = regex.firstMatch(text);
    return match?.group(2)?.trim() ?? text;
  }

  static String _extractItemName(String text) {
    print("🔍 Extracting item name from: '$text'"); // Debug log

    // Handle "add [item] to cart" FIRST (this was missing)
    final addToCartRegex = RegExp(r'(add)\s+(.+?)\s+(to cart|to the cart)');
    final addToCartMatch = addToCartRegex.firstMatch(text);
    if (addToCartMatch != null) {
      final item = addToCartMatch.group(2)?.trim() ?? text;
      print("✅ Found 'add to cart' item: '$item'");
      return item;
    }

    // Handle "remove [item] from cart"
    final removeRegex = RegExp(r'(remove)\s+(.+?)\s+(from cart|from the cart)');
    final removeMatch = removeRegex.firstMatch(text);
    if (removeMatch != null) {
      final item = removeMatch.group(2)?.trim() ?? text;
      print("✅ Found 'remove from cart' item: '$item'");
      return item;
    }

    // Handle "increase [item] quantity"
    final increaseRegex = RegExp(r'(increase|more)\s+(.+?)\s+(quantity|item)');
    final increaseMatch = increaseRegex.firstMatch(text);
    if (increaseMatch != null) {
      final item = increaseMatch.group(2)?.trim() ?? text;
      print("✅ Found 'increase quantity' item: '$item'");
      return item;
    }

    // Handle "decrease [item] quantity"
    final decreaseRegex = RegExp(
      r'(decrease|less|reduce)\s+(.+?)\s+(quantity|item)',
    );
    final decreaseMatch = decreaseRegex.firstMatch(text);
    if (decreaseMatch != null) {
      final item = decreaseMatch.group(2)?.trim() ?? text;
      print("✅ Found 'decrease quantity' item: '$item'");
      return item;
    }

    // Handle simple "add [item]" as fallback
    final addRegex = RegExp(r'(add)\s+(.+)');
    final addMatch = addRegex.firstMatch(text);
    if (addMatch != null) {
      final item = addMatch.group(2)?.trim() ?? text;
      print("✅ Found simple 'add' item: '$item'");
      return item;
    }

    // Handle simple "remove [item]" as fallback
    final removeSimpleRegex = RegExp(r'(remove)\s+(.+)');
    final removeSimpleMatch = removeSimpleRegex.firstMatch(text);
    if (removeSimpleMatch != null) {
      final item = removeSimpleMatch.group(2)?.trim() ?? text;
      print("✅ Found simple 'remove' item: '$item'");
      return item;
    }

    print("❌ No item pattern matched, returning original text");
    return text;
  }

  static String _extractMood(String text) {
    final moodKeywords = {
      'happy': ['happy', 'celebrating', 'excited', 'good'],
      'lazy': ['lazy', 'tired', 'chill', 'relax'],
      'healthy': ['healthy', 'fit', 'diet', 'light'],
      'adventurous': ['adventurous', 'try something', 'new'],
      'comfort': ['comfort', 'cozy', 'warm'],
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

  static String _extractCategory(String text) {
    final categories = [
      'rice',
      'main course',
      'appetizer',
      'dessert',
      'beverage',
    ];
    for (final category in categories) {
      if (text.contains(category)) {
        return category;
      }
    }
    return 'all';
  }

  static String _extractNavigation(String text) {
    if (text.contains('home')) return 'home';
    if (text.contains('cart')) return 'cart';
    if (text.contains('food')) return 'food';
    if (text.contains('speak')) return 'speak';
    if (text.contains('game')) return 'games';
    if (text.contains('restaurant')) return 'restaurant';
    return 'home';
  }
}
