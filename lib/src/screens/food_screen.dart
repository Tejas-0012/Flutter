// food_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:platter/src/models/restaurant.dart';
import 'package:platter/src/models/menu_items.dart' hide RestaurantCoords;
import 'package:platter/src/screens/selected_restaurant_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../navigation/main_navigator.dart';
import '../components/cart_footer.dart';

final String BASE_URL = getBaseUrl();

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://127.0.0.1:5000';
  } else if (Platform.isAndroid) {
    return 'http://10.0.2.2:5000';
  } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return 'http://127.0.0.1:5000';
  } else {
    return 'http://192.168.1.7:5000';
  }
}

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  List<MenuItem> _menuItems = [];
  List<MenuItem> _filteredItems = [];
  List<Restaurant> _restaurants = [];
  bool _loading = true;
  String? _error;

  // Search and Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String? _selectedMood;

  // Mood categories
  final List<Map<String, String>> _moodCards = [
    {'id': '1', 'title': '🍕 Comfort', 'mood': 'comfort'},
    {'id': '2', 'title': '🥗 Healthy', 'mood': 'healthy'},
    {'id': '3', 'title': '🎉 Celebrate', 'mood': 'celebrating'},
    {'id': '4', 'title': '💼 Work', 'mood': 'working'},
    {'id': '5', 'title': '💕 Date', 'mood': 'romantic'},
    {'id': '6', 'title': '🌱 Vegan', 'mood': 'vegan'},
  ];

  // Food categories
  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': '🍽️'},
    {'id': 'Rice', 'name': 'Rice', 'icon': '🍚'},
    {'id': 'Main Course', 'name': 'Main Course', 'icon': '🍛'},
    {'id': 'Starter', 'name': 'Starter', 'icon': '🥗'},
    {'id': 'Dessert', 'name': 'Desserts', 'icon': '🍰'},
    {'id': 'Beverage', 'name': 'Drinks', 'icon': '🥤'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Load menu items
      final menuResponse = await http.get(Uri.parse('$BASE_URL/menu'));
      if (menuResponse.statusCode == 200) {
        final List<dynamic> menuData = json.decode(menuResponse.body);
        final menuItems = menuData
            .map((item) => MenuItem.fromJson(item))
            .toList();

        // Load restaurants to match with menu items
        final restaurantsResponse = await http.get(
          Uri.parse('$BASE_URL/restuarant'),
        );
        if (restaurantsResponse.statusCode == 200) {
          final List<dynamic> restaurantData = json.decode(
            restaurantsResponse.body,
          );
          final restaurants = restaurantData
              .map((item) => Restaurant.fromJson(item))
              .toList();

          if (mounted) {
            setState(() {
              _menuItems = menuItems;
              _restaurants = restaurants;
              _filteredItems = menuItems;
              _loading = false;
            });
          }
        } else {
          throw Exception(
            'Failed to load restaurants: ${restaurantsResponse.statusCode}',
          );
        }
      } else {
        throw Exception('Failed to load menu: ${menuResponse.statusCode}');
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

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _applyFilters();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  void _filterByCategory(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _applyFilters();
    });
  }

  void _handleMoodSelect(String mood) {
    setState(() {
      _selectedMood = _selectedMood == mood ? null : mood;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<MenuItem> filtered = _menuItems;

    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Apply mood filter
    if (_selectedMood != null) {
      filtered = _filterByMood(filtered, _selectedMood!);
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  List<MenuItem> _filterByMood(List<MenuItem> items, String mood) {
    switch (mood) {
      case 'healthy':
        return items
            .where(
              (item) =>
                  (item.dietaryInfo.calories ?? 0) < 500 ||
                  (item.dietaryInfo.tags.contains('healthy') ?? false),
            )
            .toList();
      case 'comfort':
        return items
            .where(
              (item) =>
                  item.category == 'Main Course' ||
                  (item.dietaryInfo.tags.contains('comfort') ?? false),
            )
            .toList();
      case 'vegan':
        return items
            .where((item) => (item.dietaryInfo.isVegan ?? false))
            .toList();
      case 'celebrating':
        return items
            .where((item) => item.category == 'Dessert' || item.price > 200)
            .toList();
      default:
        return items;
    }
  }

  void _navigateToRestaurant(MenuItem menuItem) {
    final restaurant = _restaurants.firstWhere(
      (r) => r.id == menuItem.restaurantId,
      orElse: () => Restaurant(
        id: '',
        name: 'Unknown Restaurant',
        cuisineType: '',
        description: '',
        image: '',
        logo: '',
        averageRating: 0,
        estimatedDeliveryTime: '',
        address: Address(
          street: '',
          city: '',
          state: '',
          zipCode: '',
          country: '',
          coordinates: Coordinates(lat: 0.0, lng: 0.0),
        ),
      ),
    );

    if (restaurant.id.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              SelectedRestaurantScreen(restaurant: restaurant),
        ),
      );
    }
  }

  String _getResultsText() {
    if (_searchQuery.isNotEmpty && _selectedCategory != 'all') {
      return 'Showing ${_filteredItems.length} results for "$_searchQuery" in ${_categories.firstWhere((cat) => cat['id'] == _selectedCategory)['name']}';
    } else if (_searchQuery.isNotEmpty) {
      return 'Showing ${_filteredItems.length} results for "$_searchQuery"';
    } else if (_selectedCategory != 'all') {
      return 'Showing ${_filteredItems.length} ${_categories.firstWhere((cat) => cat['id'] == _selectedCategory)['name']} items';
    } else if (_selectedMood != null) {
      final mood = _moodCards.firstWhere((m) => m['mood'] == _selectedMood);
      return 'Showing ${_filteredItems.length} ${mood['title']} items';
    }
    return 'Showing all ${_filteredItems.length} items';
  }

  Widget _buildMenuItem(MenuItem item) {
    final restaurant = _restaurants.firstWhere(
      (r) => r.id == item.restaurantId,
      orElse: () => Restaurant(
        id: '',
        name: 'Unknown Restaurant',
        cuisineType: '',
        description: '',
        image: '',
        logo: '',
        averageRating: 0,
        estimatedDeliveryTime: '',
        address: Address(
          street: '',
          city: '',
          state: '',
          zipCode: '',
          country: '',
          coordinates: Coordinates(lat: 0.0, lng: 0.0),
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: item.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.images.first,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                ),
              )
            : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${item.price.toStringAsFixed(0)} • ${item.category}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToRestaurant(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => MainNavigator.switchToTab(0),
        ),
        title: const Text(
          'Discover Food',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              // ✅ NEW - ADD STACK FOR OVERLAY
              children: [
                // Main content
                CustomScrollView(
                  slivers: [
                    // Sticky Search Bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SearchHeaderDelegate(
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        onClearSearch: _clearSearch,
                      ),
                    ),

                    // Sticky Mood Filters
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _MoodHeaderDelegate(
                        moodCards: _moodCards,
                        selectedMood: _selectedMood,
                        onMoodSelect: _handleMoodSelect,
                      ),
                    ),

                    // Sticky Category Filters
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryHeaderDelegate(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        onCategorySelect: _filterByCategory,
                      ),
                    ),

                    // Results Info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _getResultsText(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                    // Scrollable Menu Items
                    _filteredItems.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No items found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = _filteredItems[index];
                              return _buildMenuItem(item);
                            }, childCount: _filteredItems.length),
                          ),

                    // Add bottom padding to prevent content overlap with CartFooter
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80), // Space for CartFooter
                    ),
                  ],
                ),

                // CartFooter positioned at bottom
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CartFooter(), // Your real CartFooter
                ),
              ],
            ),
    );
  }
}

// Header Delegates for Sticky Headers
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onClearSearch;

  _SearchHeaderDelegate({
    required this.searchController,
    required this.searchQuery,
    required this.onClearSearch,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search food items...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: onClearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class _MoodHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<Map<String, String>> moodCards;
  final String? selectedMood;
  final Function(String) onMoodSelect;

  _MoodHeaderDelegate({
    required this.moodCards,
    required this.selectedMood,
    required this.onMoodSelect,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: moodCards.length,
          itemBuilder: (context, index) {
            final mood = moodCards[index];
            final isSelected = selectedMood == mood['mood'];
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(mood['title']!),
                selected: isSelected,
                onSelected: (selected) => onMoodSelect(mood['mood']!),
                backgroundColor: Colors.grey.shade100,
                selectedColor: const Color(0xFFFF6B35),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<Map<String, String>> categories;
  final String selectedCategory;
  final Function(String) onCategorySelect;

  _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelect,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category['id'];
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category['name']!),
                selected: isSelected,
                onSelected: (selected) => onCategorySelect(category['id']!),
                backgroundColor: Colors.grey.shade100,
                selectedColor: const Color(0xFFFF6B35),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
