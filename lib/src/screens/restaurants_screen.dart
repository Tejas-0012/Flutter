// screens/restaurants_screen.dart
import 'package:flutter/material.dart';
import 'package:platter/src/navigation/main_navigator.dart';
import '../models/restaurant.dart';
import '../services/restaurant_services.dart';
import '../utils/logo_map.dart';
import 'selected_restaurant_screen.dart';
import 'package:provider/provider.dart';
import '../context/voice_state.dart';
import '../utils/voice_command_processor.dart';
import '../screens/voice_assistant.dart';
import '../components/cart_footer.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  List<Restaurant> _currentRestaurants = [];
  final RestaurantService _restaurantService = RestaurantService();
  final VoiceAssistant _voiceAssistant = VoiceAssistant();
  late Future<List<Restaurant>> _restaurantsFuture;
  final TextEditingController _searchController = TextEditingController();

  List<Restaurant> _getCurrentRestaurants() {
    return _currentRestaurants;
  }

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = _restaurantService.fetchRestaurants();
    _setupVoiceAssistant();
  }

  void _setupVoiceAssistant() {
    _voiceAssistant.setScreenContext('restaurant');
    _voiceAssistant.setCallbacks(
      onCommandDetected: (command) {
        if (mounted) {
          _handleVoiceCommand(command);
        }
      },
      onListeningStateChanged: (listening) {
        if (mounted) {
          context.read<VoiceState>().setListeningState(listening);
        }
      },
    );
  }

  void _handleVoiceCommand(String command) {
    if (!mounted) return;

    try {
      final voiceState = context.read<VoiceState>();
      final restaurants = _getCurrentRestaurants(); // GET RESTAURANTS

      final processed = VoiceCommandProcessor.processCommand(
        command,
        'restaurant',
        restaurants: restaurants, // PASS TO PROCESSOR
      );

      print(
        "🎯 Restaurant voice command: '$command' -> ${processed['command']}",
      );

      switch (processed['command']) {
        case 'open_restaurant': // THIS HANDLES "MTR"
          if (mounted) {
            final restaurant = processed['data'] as Restaurant;
            _voiceAssistant.speak("Opening ${restaurant.name}");
            _navigateToSelectedRestaurant(restaurant);
            voiceState.setListeningState(false);
          }
          break;

        case 'search_restaurants':
          if (mounted) {
            final query = processed['data'] as String;
            _searchController.text = query;
            setState(() {}); // Trigger search
            _voiceAssistant.speak("Searching for $query");
            voiceState.setListeningState(false);
          }
          break;

        case 'navigate':
          if (mounted) {
            final destination = processed['data'] as String;
            _handleVoiceNavigation(destination);
            voiceState.setListeningState(false);
          }
          break;

        default:
          if (mounted) {
            _voiceAssistant.speak("Sorry, I didn't understand that command");
            voiceState.setListeningState(false);
          }
      }
    } catch (e) {
      print('❌ Error in restaurant voice command: $e');
    }
  }

  void _navigateToSelectedRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectedRestaurantScreen(restaurant: restaurant),
      ),
    );
  }

  void _handleVoiceNavigation(String destination) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (destination) {
        case 'home':
          _voiceAssistant.speak("Going home");
          MainNavigator.switchToTab(0); // Go back to home
          break;

        case 'cart':
          _voiceAssistant.speak("Taking you to cart");
          // Navigate to cart - you'll need to implement this
          break;

        default:
          _voiceAssistant.speak("I can't navigate to $destination from here");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 237, 237),
      appBar: AppBar(
        title: const Text(
          'Restaurants',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              _voiceAssistant.init();
              final voiceState = Provider.of<VoiceState>(
                context,
                listen: false,
              );
              voiceState.setListeningState(true);
            },
            icon: const Icon(Icons.mic, color: Colors.black),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search restaurants...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),

              // Restaurant List with bottom padding
              Expanded(
                child: FutureBuilder<List<Restaurant>>(
                  future: _restaurantsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator();
                    } else if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    } else if (snapshot.hasData) {
                      final restaurants = snapshot.data!;
                      final filteredRestaurants = _filterRestaurants(
                        restaurants,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 80,
                        ), // Space for CartFooter
                        child: _buildRestaurantList(filteredRestaurants),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 80,
                        ), // Space for CartFooter
                        child: _buildEmptyState(),
                      );
                    }
                  },
                ),
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

  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants) {
    if (_searchController.text.isEmpty) {
      return restaurants;
    }
    return restaurants.where((restaurant) {
      final searchLower = _searchController.text.toLowerCase();
      return restaurant.name.toLowerCase().contains(searchLower) ||
          restaurant.cuisineType.toLowerCase().contains(searchLower) ||
          restaurant.description.toLowerCase().contains(searchLower);
    }).toList();
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          SizedBox(height: 16),
          Text('Loading restaurants...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Failed to load restaurants',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _restaurantsFuture = _restaurantService.fetchRestaurants();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No restaurants found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList(List<Restaurant> restaurants) {
    _currentRestaurants = restaurants;
    if (restaurants.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return _buildRestaurantCard(restaurant);
      },
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to restaurant details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SelectedRestaurantScreen(restaurant: restaurant),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xfff8f9fa),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LogoMap.getLogoWidget(
                    restaurant.logo,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),
              // Restaurant Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.cuisineType,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating
                        Icon(Icons.star, color: Colors.orange[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // Delivery Time
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[500],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.estimatedDeliveryTime,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.address.street}, ${restaurant.address.city}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceAssistant.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
