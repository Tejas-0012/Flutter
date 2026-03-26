// 🔹 IMPORT YOUR MODEL
import 'package:platter/src/models/menu_items.dart' hide RestaurantCoords;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:platter/src/models/restaurant.dart'; // Contains Coordinates and Restaurant
import 'package:platter/src/navigation/main_navigator.dart';
import 'package:provider/provider.dart';
import 'package:platter/src/context/cart_provider.dart'; // Contains CartProvider
import 'menu_model.dart';
import '../context/voice_state.dart';
import '../utils/voice_command_processor.dart';
import '../navigation/main_navigator.dart';
import '../screens/voice_assistant.dart';
import '../../widgets/voice_listening_overlay.dart'; // ADD THIS

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

final String BASE_URL = getBaseUrl();
String getBaseUrl() {
  return "https://api-node-0hjb.onrender.com";
}

class MenuScreen extends StatefulWidget {
  final Restaurant? restaurant;
  const MenuScreen({super.key, this.restaurant});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String _baseUrl = 'https://api-node-0hjb.onrender.com';
  List<MenuItem> _menuItems = [];
  List<MenuItem> _filteredItems = [];
  bool _loading = true;
  String? _error;
  final VoiceAssistant _voiceAssistant = VoiceAssistant();

  // 🔹 CATEGORIES AND FILTER STATE
  final List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'All', 'icon': '🍽️'},
    {'id': 'Rice', 'name': 'Rice', 'icon': '🍚'},
    {'id': 'Main Course', 'name': 'Main Course', 'icon': '🍛'},
    {'id': 'Starter', 'name': 'Starter', 'icon': '🥗'},
    {'id': 'Dessert', 'name': 'Desserts', 'icon': '🍰'},
    {'id': 'Beverage', 'name': 'Drinks', 'icon': '🥤'},
  ];

  String _selectedCategory = 'all';

  // 🔹 ADD SEARCH FUNCTIONALITY
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
    // Add listener for search controller
    _searchController.addListener(_onSearchChanged);
    _setupVoiceAssistant();
  }

  void _setupVoiceAssistant() {
    _voiceAssistant.setScreenContext('menu');
    _voiceAssistant.setCallbacks(
      onCommandDetected: (command) {
        if (mounted) {
          _handleVoiceCommand(command);
        }
      },
      onListeningStateChanged: (listening) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final voiceState = Provider.of<VoiceState>(
                context,
                listen: false,
              );
              voiceState.setListeningState(listening);
            }
          });
        }
      },
    );
  }

  void _handleVoiceCommand(String command) {
    if (!mounted) return;

    try {
      final voiceState = Provider.of<VoiceState>(context, listen: false);
      final processed = VoiceCommandProcessor.processCommand(command, 'menu');

      print("🎯 Menu voice command: '$command' -> ${processed['command']}");

      switch (processed['command']) {
        case 'add_to_cart':
          final itemName = processed['data'] as String;
          _handleVoiceAddToCart(itemName);
          voiceState.updateCommandResult(
            'add_to_cart',
            'Adding $itemName to cart',
          );
          voiceState.setListeningState(false); // ADD THIS
          break;

        case 'search_menu':
          final query = processed['data'] as String;
          _handleVoiceSearch(query);
          voiceState.updateCommandResult('search_menu', 'Searching for $query');
          voiceState.setListeningState(false); // ADD THIS
          break;

        case 'filter_menu':
          final category = processed['data'] as String;
          _handleVoiceFilter(category);
          voiceState.updateCommandResult(
            'filter_menu',
            'Filtering by $category',
          );
          voiceState.setListeningState(false); // ADD THIS
          break;

        case 'navigate':
          final destination = processed['data'] as String;
          _handleVoiceNavigation(destination);
          voiceState.setListeningState(false); // ADD THIS
          break;

        default:
          _voiceAssistant.speak("Sorry, I didn't understand that menu command");
          voiceState.setListeningState(false); // ADD THIS
      }
    } catch (e) {
      print('❌ Error in menu voice command: $e');
      if (mounted) {
        final voiceState = Provider.of<VoiceState>(context, listen: false);
        voiceState.setListeningState(false);
      }
    }
  }

  void _handleVoiceNavigation(String destination) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (destination) {
        case 'home':
          _voiceAssistant.speak("Going home");
          Navigator.popUntil(context, (route) => route.isFirst);
          break;

        case 'cart':
          _voiceAssistant.speak("Taking you to cart");
          MainNavigator.switchToTab(4);
          break;

        case 'restaurant':
          _voiceAssistant.speak("Going back to restaurants");
          Navigator.pop(context);
          break;

        case 'back':
          _voiceAssistant.speak("Going back");
          Navigator.pop(context);
          break;

        default:
          _voiceAssistant.speak("I can't navigate to $destination from menu");
      }
    });
  }

  void _handleVoiceAddToCart(String itemName) {
    // Find item by name in filtered items
    final item = _filteredItems.firstWhere(
      (item) => item.name.toLowerCase().contains(itemName.toLowerCase()),
      orElse: () => MenuItem(
        menuItemId: '',
        restaurantId: '',
        name: '',
        description: '',
        price: 0,
        category: '',
        subCategory: '',
        dietaryInfo: DietaryInfo(
          isVegetarian: false,
          isVegan: false,
          isGlutenFree: false,
          isDairyFree: false,
          isNutFree: false,
          isSpicy: false,
          spiceLevel: 0,
          calories: 0,
          allergens: [],
          tags: [],
        ),
        climateTags: [],
        seasonalSuitable: ['all'],
        mealContext: [],
        isAvailable: true,
        preparationTime: 0,
        images: [],
        popularity: 0,
        rating: 0,
        ratingCount: 0,
        displayOrder: 0,
      ),
    );

    if (item.menuItemId.isNotEmpty) {
      _handleAddToCart(context, item);
      _voiceAssistant.speak("Added $itemName to cart");
    } else {
      _voiceAssistant.speak("Could not find $itemName in the menu");
    }
  }

  void _handleVoiceSearch(String query) {
    setState(() {
      _searchController.text = query;
      _searchQuery = query;
      _applyFilters();
    });
    _voiceAssistant.speak("Searching for $query");
  }

  void _handleVoiceFilter(String category) {
    String categoryId = 'all';

    // Map voice category to actual category ID
    final categoryMap = {
      'rice': 'Rice',
      'main course': 'Main Course',
      'appetizer': 'Appetizer',
      'starter': 'Appetizer',
      'dessert': 'Dessert',
      'desserts': 'Dessert',
      'beverage': 'Beverage',
      'drinks': 'Beverage',
      'all': 'all',
    };

    categoryId = categoryMap[category.toLowerCase()] ?? 'all';

    setState(() {
      _selectedCategory = categoryId;
      _applyFilters();
    });

    final categoryName = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'name': 'All'},
    )['name'];

    _voiceAssistant.speak("Filtering by $categoryName");
  }

  @override
  void dispose() {
    _voiceAssistant.dispose();
    super.dispose();
  }

  Future<void> _loadMenuItems() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/menu'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final List<MenuItem> allItems = data
            .map((item) => MenuItem.fromJson(item))
            .toList();

        final List<MenuItem> filtered = allItems
            .where((item) => item.restaurantId == widget.restaurant?.id)
            .toList();

        if (mounted) {
          setState(() {
            _menuItems = filtered;
            _filteredItems = filtered;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load menu items';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // 🔹 CATEGORY FILTER METHOD
  void _filterByCategory(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _applyFilters();
    });
  }

  // 🔹 SEARCH HANDLER
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _applyFilters();
    });
  }

  // 🔹 COMBINED FILTER METHOD (Category + Search) - UPDATED: SEARCH ONLY NAME
  void _applyFilters() {
    List<MenuItem> filtered = _menuItems;

    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Apply search filter - ONLY SEARCH IN NAME
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) => (item.name ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  // 🔹 CLEAR SEARCH
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  // =============================================================
  // 🔹 ADD TO CART HANDLER (UNCHANGED)
  // =============================================================
  void _handleAddToCart(BuildContext context, MenuItem item) {
    final restaurant = widget.restaurant;
    if (restaurant == null) return;

    final cartProvider = context.read<CartProvider>();

    try {
      cartProvider.addToCart(
        restaurant.id,
        restaurant.name,
        item,
        restaurantCoords: RestaurantCoords(
          lat: restaurant.address.coordinates.lat,
          lng: restaurant.address.coordinates.lng,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added to cart!'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (e.toString().contains('different restaurant')) {
        _showConflictDialog(context, item, cartProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔹 HELPER METHOD FOR RESULTS TEXT
  String _getResultsText() {
    if (_searchQuery.isNotEmpty && _selectedCategory != 'all') {
      return 'Showing ${_filteredItems.length} results for "$_searchQuery" in ${categories.firstWhere((cat) => cat['id'] == _selectedCategory)['name']}';
    } else if (_searchQuery.isNotEmpty) {
      return 'Showing ${_filteredItems.length} results for "$_searchQuery"';
    } else if (_selectedCategory != 'all') {
      return 'Showing ${_filteredItems.length} ${categories.firstWhere((cat) => cat['id'] == _selectedCategory)['name']} items';
    }
    return 'Showing all ${_filteredItems.length} items';
  }

  // 🔹 HELPER METHOD FOR EMPTY STATE TEXT
  String _getEmptyStateText() {
    if (_searchQuery.isNotEmpty && _selectedCategory != 'all') {
      return 'No items found for "$_searchQuery" in ${categories.firstWhere((cat) => cat['id'] == _selectedCategory)['name']}';
    } else if (_searchQuery.isNotEmpty) {
      return 'No items found for "$_searchQuery"';
    } else if (_selectedCategory != 'all') {
      return 'No ${categories.firstWhere((cat) => cat['id'] == _selectedCategory)['name']} items available';
    }
    return 'No menu items available';
  }

  // =============================================================
  // 🔹 CONFLICT DIALOG (UNCHANGED)
  // =============================================================
  void _showConflictDialog(
    BuildContext context,
    MenuItem newItem,
    CartProvider cartProvider,
  ) {
    final activeId = cartProvider.activeRestaurantId;
    if (activeId == null) return;

    final existingCart = cartProvider.carts[activeId]!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Existing Cart?'),
          content: Text(
            'Your cart already contains items from "${existingCart.restaurantName}". '
            'Do you want to clear the current cart and add "${newItem.name}" from ${widget.restaurant!.name}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Yes, Clear Cart',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                cartProvider.clearCart(activeId);
                Navigator.of(dialogContext).pop();
                _handleAddToCart(context, newItem);
              },
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // 🔹 UPDATED UI WITH SEARCH BAR
  // =============================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_menuItems.isEmpty) {
      return Center(
        child: Text(
          'No menu items found for ${widget.restaurant?.name ?? ""}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Consumer<VoiceState>(
      builder: (context, voiceState, child) {
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... ALL YOUR EXISTING MENU CONTENT ...
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff333333),
                    ),
                  ),
                ),

                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search menu items...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // CATEGORY FILTER CHIPS
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category['id'];
                      return GestureDetector(
                        onTap: () => _filterByCategory(category['id']!),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF6B35)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B35)
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category['icon']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category['name']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // SEARCH RESULTS INFO
                if (_searchQuery.isNotEmpty || _selectedCategory != 'all')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _getResultsText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // MENU ITEMS LIST
                ..._filteredItems.map((item) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => MenuItemModal(
                            menuItem: item,
                            onAddToCart: () {
                              Navigator.of(context).pop();
                              _handleAddToCart(context, item);
                            },
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        child: Row(
                          children: [
                            // ITEM IMAGE/ICON
                            item.images.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.images.first,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.fastfood,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.fastfood,
                                    size: 40,
                                    color: Colors.grey,
                                  ),

                            const SizedBox(width: 12),

                            // ITEM DETAILS
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description.isNotEmpty
                                        ? item.description
                                        : 'No description available',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ADD TO CART BUTTON
                            SizedBox(
                              height: 30,
                              child: OutlinedButton(
                                onPressed: () =>
                                    _handleAddToCart(context, item),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.green,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // EMPTY STATE
                if (_filteredItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyStateText(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: _clearSearch,
                            child: const Text('Clear search'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            // VOICE LISTENING OVERLAY
            if (voiceState.isListening)
              VoiceListeningOverlay(
                onClose: () {
                  final voiceState = Provider.of<VoiceState>(
                    context,
                    listen: false,
                  );
                  voiceState.setListeningState(false);
                },
              ),
          ],
        );
      },
    );
  }
}
