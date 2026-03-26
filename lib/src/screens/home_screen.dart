import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:platter/src/navigation/main_navigator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../utils/logo_map.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'selected_restaurant_screen.dart';
import 'package:platter/src/models/restaurant.dart';
import '../components/mood_cards.dart';
import '../context/voice_state.dart';
import '../utils/voice_command_processor.dart';
import '../screens/voice_assistant.dart';
import '../../widgets/voice_listening_overlay.dart';
import '../screens/restaurants_screen.dart';
import '../components/cart_footer.dart';

// --- API CONFIGURATION ---
final String BASE_URL = getBaseUrl();

class WeatherData {
  final double temperature;
  final String condition;
  final String city;
  final String category;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.city,
    required this.category,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'] ?? {};
    return WeatherData(
      temperature: (weather['temperature'] ?? 0).toDouble(),
      condition: weather['condition'] ?? 'unknown',
      city: weather['city'] ?? 'unknown',
      category: weather['category'] ?? 'moderate',
    );
  }
}

class ClimateRecommendation {
  final bool success;
  final WeatherData weather;
  final String message;
  final List<dynamic> recommendations;
  final int totalResults;

  ClimateRecommendation({
    required this.success,
    required this.weather,
    required this.message,
    required this.recommendations,
    required this.totalResults,
  });

  factory ClimateRecommendation.fromJson(Map<String, dynamic> json) {
    return ClimateRecommendation(
      success: json['success'] as bool,
      weather: WeatherData.fromJson(json['weather'] as Map<String, dynamic>),
      message: json['message'] as String,
      recommendations: json['recommendations'] as List<dynamic>,
      totalResults: json['totalResults'] as int,
    );
  }
}

String getBaseUrl() {
  if (kIsWeb) {
    return 'https://api-node-0hjb.onrender.com';
  } else if (Platform.isAndroid) {
    return 'https://api-node-0hjb.onrender.com';
  } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return 'https://api-node-0hjb.onrender.com';
  } else {
    return 'https://api-node-0hjb.onrender.com';
  }
}

// --- API FUNCTIONS ---
Future<List<Restaurant>> loadRestaurants() async {
  final url = Uri.parse('$BASE_URL/restuarant');
  try {
    print('🌐 Fetching restaurants from: $url');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      List<dynamic> restaurantList;
      if (data is List<dynamic>) {
        restaurantList = data;
      } else if (data is Map<String, dynamic> &&
          data.containsKey('restaurants')) {
        restaurantList = data['restaurants'] as List<dynamic>;
      } else {
        throw Exception('Unexpected API response format');
      }
      final restaurants = restaurantList
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
      return restaurants;
    } else {
      throw Exception('Failed to load restaurants: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error in loadRestaurants: $e');
    throw Exception('Network error: $e');
  }
}

// NEW: Function to fetch climate recommendations (without mood)
Future<ClimateRecommendation> fetchClimateRecommendations(
  double lat,
  double lon,
) async {
  final url = Uri.parse(
    '$BASE_URL/api/recommendations/climate?lat=$lat&lon=$lon',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return ClimateRecommendation.fromJson(data);
    } else {
      throw Exception(
        'Failed to get climate recommendations: ${response.statusCode}',
      );
    }
  } catch (e) {
    throw Exception('Climate recommendation service error: $e');
  }
}

Future<WeatherData> getCurrentWeather(double lat, double lon) async {
  final List<String> possibleEndpoints = [
    '$BASE_URL/api/recommendations/climate?lat=$lat&lon=$lon',
    '$BASE_URL/climate',
    '$BASE_URL/api/climate',
  ];

  for (final url in possibleEndpoints) {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
    } catch (e) {
      print('❌ Weather endpoint failed: $e');
    }
  }

  return WeatherData(
    temperature: 23.0,
    condition: "moderate",
    city: "Bengaluru",
    category: "moderate",
  );
}

Future<ClimateRecommendation> handleMoodSelect(
  double lat,
  double lon,
  String mood,
) async {
  final url = Uri.parse(
    '$BASE_URL/api/recommendations/climate?lat=$lat&lon=$lon&mood=$mood',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return ClimateRecommendation.fromJson(data);
    } else {
      throw Exception('Failed to get recommendation: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Recommendation service error: $e');
  }
}

// --- LOCATION SERVICE ---
class LocationService {
  static Future<Map<String, double>> getCurrentLocation() async {
    return {'lat': 12.970931, 'lon': 77.513370};
  }
}

// --- HELPER WIDGETS ---

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String text;

  const _ActionButton({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width / 3) - 20,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xff333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibilityButton extends StatelessWidget {
  final String emoji;
  final String text;

  const _AccessibilityButton({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width / 4) - 10,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xff666666)),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xfff8f9fa),
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: LogoMap.getLogoWidget(
                  restaurant.logo,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant.cuisineType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⭐ ${restaurant.averageRating}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xff666666),
                        ),
                      ),
                      Text(
                        '🕒 ${restaurant.estimatedDeliveryTime}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xff666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- UPDATED HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Restaurant> _items = [];
  bool _loading = true;
  String? _error;
  String? _selectedMood;
  int _visibleCount = 4;
  WeatherData? _weatherData;
  bool _climateLoading = false;
  Map<String, double>? _userLocation;
  final VoiceAssistant _voiceAssistant = VoiceAssistant();

  // UPDATED: Combined recommendations state
  List<dynamic> _recommendations = [];
  String _recommendationMessage = "";
  bool _isLoadingRecommendations = true;
  bool _showMoodRecommendations = false;

  // NEW: Fetch climate recommendations on app start
  Future<void> _fetchClimateRecommendations() async {
    if (_userLocation == null) return;

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final response = await fetchClimateRecommendations(
        _userLocation!['lat']!,
        _userLocation!['lon']!,
      );

      if (response.success) {
        setState(() {
          _recommendations = response.recommendations;
          _recommendationMessage = response.message;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print('Climate recommendation error: $e');
      setState(() {
        _isLoadingRecommendations = false;
        _recommendations = [];
        _recommendationMessage = "Great options for today's weather!";
      });
    }
  }

  // UPDATED: Build recommendations widget (handles both climate and mood)
  Widget _buildRecommendations() {
    if (_isLoadingRecommendations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            _showMoodRecommendations
                ? "Recommended for your mood"
                : "AI Weather Recommendations",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            _recommendationMessage,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final item = _recommendations[index];
              return GestureDetector(
                onTap: () => print('Selected: ${item['name']}'),
                child: Container(
                  width: 160,
                  margin: EdgeInsets.only(right: 12, left: index == 0 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: Image.network(
                          item['image'] ?? '',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.fastfood,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Unknown Item',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${item['price']}',
                              style: const TextStyle(
                                color: Color(0xff777777),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _setupVoiceAssistant();
    _initializeApp();
  }

  void _setupVoiceAssistant() {
    _voiceAssistant.setScreenContext('home');
    _voiceAssistant.setCallbacks(
      onCommandDetected: (command) {
        if (mounted) {
          _handleVoiceCommand(command);
        } else {
          print('⚠️ Widget not mounted, ignoring command: $command');
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
    // CRITICAL: Check if widget is still mounted
    if (!mounted) {
      print('🚫 Widget unmounted, ignoring voice command: $command');
      return;
    }

    try {
      final voiceState = context.read<VoiceState>();
      final processed = VoiceCommandProcessor.processCommand(command, 'home');

      print(
        "🎯 Voice command: '$command' -> ${processed['command']} : ${processed['data']}",
      );

      // Check mounted before each operation
      switch (processed['command']) {
        case 'set_mood':
          if (mounted) {
            final mood = processed['data'] as String;
            _handleVoiceMood(mood);
            voiceState.updateCommandResult('set_mood', 'Mood set to $mood');
            voiceState.setListeningState(false);
          }
          break;

        case 'navigate':
          if (mounted) {
            final destination = processed['data'] as String;
            _handleVoiceNavigation(destination);
            voiceState.updateCommandResult('navigate', 'Going to $destination');
            voiceState.setListeningState(false);
          }
          break;

        case 'close_voice':
        case 'close':
        case 'cancel':
          if (mounted) {
            voiceState.setListeningState(false);
            _voiceAssistant.speak("Closing voice assistant");
          }
          break;

        case 'show_help':
          if (mounted) {
            _voiceAssistant.speak(
              "You can say: go to food, cart, games, or speak",
            );
          }
          break;

        case 'search_restaurants':
          if (mounted) {
            final query = processed['data'] as String;
            _voiceAssistant.speak("Searching for $query");
            // Add your search logic here
            voiceState.setListeningState(false);
          }
          break;

        default:
          if (mounted && _tryHandleAsNavigation(command)) {
            voiceState.setListeningState(false);
            break;
          }
          if (mounted) {
            _voiceAssistant.speak("Sorry, I didn't understand that command");
            voiceState.setListeningState(false);
          }
      }
    } catch (e) {
      print('❌ Error in voice command handler: $e');
      if (mounted) {
        context.read<VoiceState>().setListeningState(false);
      }
    }
  }

  void _handleVoiceNavigation(String destination) {
    if (!mounted) return;

    // Use post-frame callback for safer navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (destination) {
        case 'cart':
          _voiceAssistant.speak("Taking you to cart");
          MainNavigator.switchToTab(4);
          break;

        case 'home':
          _voiceAssistant.speak("Taking you home");
          MainNavigator.switchToTab(0);
          break;

        case 'food':
          _voiceAssistant.speak("Showing food options");
          MainNavigator.switchToTab(1);
          break;

        case 'speak':
          _voiceAssistant.speak("Opening voice commands");
          MainNavigator.switchToTab(2);
          break;

        case 'restaurant':
          _voiceAssistant.speak("Showing restaurants");
          // Use Navigator.push for non-tab screens
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RestaurantsScreen()),
          );
          break;
        case 'games':
          _voiceAssistant.speak("Let's play some games");
          MainNavigator.switchToTab(3);
          break;

        default:
          _voiceAssistant.speak("I can't navigate to $destination");
      }
    });
  }

  void _handleVoiceMood(String mood) {
    if (!mounted) return;
    _handleMoodSelect(mood);
    _voiceAssistant.speak("Great! Showing $mood options for you");
  }

  bool _tryHandleAsNavigation(String command) {
    if (!mounted) return false;

    final text = command.toLowerCase();

    if (text.contains('food') || text.contains('restaurant')) {
      _handleVoiceNavigation('food');
      return true;
    }
    if (text.contains('cart')) {
      _handleVoiceNavigation('cart');
      return true;
    }
    if (text.contains('games')) {
      _handleVoiceNavigation('games');
      return true;
    }
    if (text.contains('speak') || text.contains('voice')) {
      _handleVoiceNavigation('speak');
      return true;
    }
    if (text.contains('home')) {
      _handleVoiceNavigation('home');
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _voiceAssistant.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _getCurrentLocation();
      await _loadRestaurants();
      await _fetchClimateRecommendations(); // NEW: Load climate recommendations on start
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize app: $e';
          _loading = false;
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLocation = location;
        });
      }
      await _getCurrentWeather();
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        setState(() {
          _userLocation = {'lat': 12.970931, 'lon': 77.513370};
        });
      }
      await _getCurrentWeather();
    }
  }

  Future<void> _getCurrentWeather() async {
    if (_userLocation == null) return;

    try {
      final weather = await getCurrentWeather(
        _userLocation!['lat']!,
        _userLocation!['lon']!,
      );
      if (mounted) {
        setState(() {
          _weatherData = weather;
        });
      }
    } catch (e) {
      print('Weather error: $e');
      if (mounted) {
        setState(() {
          _weatherData = WeatherData(
            temperature: 23.0,
            condition: "moderate",
            city: "Bengaluru",
            category: "moderate",
          );
        });
      }
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await loadRestaurants();
      if (mounted) {
        setState(() {
          _items = restaurants;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading restaurants: $e';
          _loading = false;
        });
      }
    }
  }

  // UPDATED: Handle mood selection
  Future<void> _handleMoodSelect(String mood) async {
    setState(() {
      _selectedMood = mood;
      _climateLoading = true;
      _showMoodRecommendations = true;
    });

    try {
      if (_userLocation != null) {
        final response = await handleMoodSelect(
          _userLocation!['lat']!,
          _userLocation!['lon']!,
          mood,
        );

        if (response.success) {
          setState(() {
            _recommendations = response.recommendations;
            _recommendationMessage = response.message;
            _climateLoading = false;
          });
        }
      }
    } catch (error) {
      print('Mood selection error: $error');
      setState(() {
        _recommendations = [];
        _recommendationMessage = 'Service unavailable. Please try again.';
        _climateLoading = false;
      });
    }
  }

  // NEW: Reset to climate recommendations
  void _resetToClimateRecommendations() {
    setState(() {
      _selectedMood = null;
      _showMoodRecommendations = false;
    });
    _fetchClimateRecommendations(); // Reload climate recommendations
  }

  String _getWeatherEmoji(String condition) {
    const emojiMap = {
      'hot': '🔥',
      'cold': '❄️',
      'rainy': '🌧️',
      'moderate': '🌤️',
      'default': '🌡️',
    };
    return emojiMap[condition] ?? emojiMap['default']!;
  }

  String? _getWeatherMessage() {
    if (_weatherData == null) return null;
    final messages = {
      'hot': "Hot! Cool meals 🍹",
      'cold': "Chilly! Warm food 🍲",
      'rainy': "Rainy! Comfort food ☔",
      'moderate': "Nice weather! 🌟",
    };
    return messages[_weatherData!.category] ?? messages['moderate'];
  }

  void _navigateToRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectedRestaurantScreen(restaurant: restaurant),
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF6B35)),
              SizedBox(height: 16),
              Text(
                'Loading delicious options...',
                style: TextStyle(color: Color(0xff666666)),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _retryInitialization,
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
          ),
        ),
      );
    }

    return Consumer<VoiceState>(
      builder: (context, voiceState, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Container(
                            color: const Color(0xFFFF6B35),
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 12,
                              bottom: 20,
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Platter',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Food for all',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _voiceAssistant.init();
                                      final voiceState =
                                          Provider.of<VoiceState>(
                                            context,
                                            listen: false,
                                          );
                                      voiceState.setListeningState(true);
                                    },
                                    icon: const Icon(
                                      Icons.mic,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  if (_weatherData != null)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '${_getWeatherEmoji(_weatherData!.condition)} Bengaluru North: ${_weatherData!.temperature}°C',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _getWeatherMessage()!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Greeting
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, Tejas! 👋',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff333333),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Text(
                                    'What to order?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff666666),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Voice Search Button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            child: GestureDetector(
                              onTap: () => print('Voice Search Tapped'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E8B57),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '🎤 Voice Search',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Mood Selection Section
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 12,
                              bottom: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'How are you feeling?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff333333),
                                  ),
                                ),
                                if (_showMoodRecommendations)
                                  TextButton(
                                    onPressed: _resetToClimateRecommendations,
                                    child: const Text(
                                      'Show Weather Recommendations',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Mood Cards
                          MoodCards(
                            onMoodSelect: _handleMoodSelect,
                            userLocation: _userLocation,
                          ),

                          // Loading indicator for mood selection
                          if (_climateLoading)
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFF6B35),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Finding perfect options...',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B35),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // RECOMMENDATIONS SECTION (Handles both climate and mood)
                          _buildRecommendations(),

                          // Featured Restaurants
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 12,
                              top: 12,
                              bottom: 8,
                            ),
                            child: Text(
                              'Featured Restaurants',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff333333),
                              ),
                            ),
                          ),

                          // Restaurant List
                          ..._items
                              .take(_visibleCount)
                              .map(
                                (restaurant) => _RestaurantCard(
                                  restaurant: restaurant,
                                  onTap: () =>
                                      _navigateToRestaurant(restaurant),
                                ),
                              ),

                          // View More/Less Button
                          if (_items.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _visibleCount = _visibleCount < _items.length
                                      ? _items.length
                                      : 4;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 16,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffff6347),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _visibleCount < _items.length
                                      ? 'View More (${_items.length - _visibleCount} more)'
                                      : 'View Less',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const CartFooter(),
                ],
              ),

              // Voice Listening Overlay
              // In your HomeScreen build method, replace the existing overlay with:
              if (voiceState.isListening)
                VoiceListeningOverlay(
                  onClose: () {
                    // Optional: Add any cleanup logic here
                    print('Overlay closed by user');
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

void main() {
  runApp(const PlatterApp());
}

class PlatterApp extends StatelessWidget {
  const PlatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platter Food App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF6B35),
        useMaterial3: false,
      ),
      home: const HomeScreen(),
    );
  }
}
