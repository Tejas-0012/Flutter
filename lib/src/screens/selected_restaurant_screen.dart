import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // For openMaps function
// For a few generic icons
import 'package:platter/src/models/restaurant.dart';
import 'package:platter/src/screens/menu_screen.dart'; // ✅ real MenuScreen
import '../components/cart_footer.dart'; // For CartFooter
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/logo_map.dart';

// NOTE: In a real Flutter app, these models would be defined in separate files (e.g., /models/restaurant.dart)

final String BASE_URL = getBaseUrl();
String getBaseUrl() {
  return "https://api-node-0hjb.onrender.com";
}

// ====================================================================
// Platform Map Linking (Replaces react-native's Linking/Platform)
// Uses the url_launcher package.
// ====================================================================

void openMaps(double lat, double lng, {String label = "Restaurant"}) async {
  // Common scheme for both platforms for simplicity using Google Maps link format
  // For production, you might want separate iOS/Android schemes as in the RN code.
  final Uri url = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label',
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    debugPrint('Could not launch $url');
    // Optionally show a dialog to the user
  }
}

// ====================================================================
// Placeholder Widgets (Assume these are imported or defined elsewhere)
// ====================================================================

// Placeholder for MenuScreen

// Placeholder for CartFooter

// ====================================================================
// Restaurant Screen (StatefulWidget)
// ====================================================================

class SelectedRestaurantScreen extends StatefulWidget {
  final Restaurant restaurant;

  // The ID is passed via the constructor (equivalent to route.params)
  const SelectedRestaurantScreen({super.key, required this.restaurant});

  @override
  State<SelectedRestaurantScreen> createState() =>
      _SelectedRestaurantScreenState();
}

class _SelectedRestaurantScreenState extends State<SelectedRestaurantScreen> {
  List<Restaurant> _allRestaurants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // This is the Flutter equivalent of useEffect(() => { load() }, []);
    _loadRestaurants();
  }

  // Equivalent to the async function 'load' in useEffect
  Future<void> _loadRestaurants() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('$BASE_URL/restuarant'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final restaurants = data
            .map((json) => Restaurant.fromJson(json))
            .toList();

        // Check if the widget is still mounted before setting state
        if (mounted) {
          setState(() {
            _allRestaurants = restaurants;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load restaurants: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Return a full screen centered activity indicator
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    final selectedRestaurant = _allRestaurants.firstWhere(
      (r) => r.id == widget.restaurant.id,
      // Provide a placeholder or handle the case where the restaurant isn't found
      orElse: () => Restaurant(
        id: '',
        name: 'Restaurant Not Found',
        cuisineType: '',
        description: 'Error: ID not found in list.',
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

    // If the restaurant wasn't found (using orElse above)
    if (selectedRestaurant.id.isEmpty &&
        selectedRestaurant.name != 'Restaurant Not Found') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Restaurant not found.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Main UI structure
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.restaurant.name,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // ScrollView equivalent
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRestaurantHeader(selectedRestaurant),
                    // MenuScreen is rendered here
                    MenuScreen(restaurant: selectedRestaurant),
                    // Add some bottom padding to prevent content overlap with footer
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // CartFooter (Fixed at the bottom - using Align or a Stack might be better
            // if you want the overlay behavior, but using the bottom area of a Column
            // or Scaffold.bottomNavigationBar is standard Flutter practice)
            const CartFooter(),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // Helper Widget Builders (Equivalent to inline RN JSX)
  // ====================================================================

  Widget _buildRestaurantHeader(Restaurant restaurant) {
    // Note: The RN code used `logoMap` for images. Here, we use a placeholder or
    // a NetworkImage if `restaurant.logo` is a URL.
    // For now, using an icon as a placeholder.
    Widget logoImage = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: const Color(0xfff8f9fa),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: LogoMap.getLogoWidget(
          restaurant.logo, // 🔹 your dynamic logo key
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );

    // If you were using images from a URL, use this instead:
    // if (restaurant.image.isNotEmpty) {
    //   logoImage = ClipRRect(
    //     borderRadius: BorderRadius.circular(40),
    //     child: Image.network(
    //       restaurant.image,
    //       width: 80,
    //       height: 80,
    //       fit: BoxFit.cover,
    //     ),
    //   );
    // }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xfff0f0f0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logoImage,
          const SizedBox(height: 15),
          Text(
            restaurant.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            restaurant.cuisineType.toUpperCase(),
            style: const TextStyle(fontSize: 16, color: Color(0xff666666)),
          ),
          const SizedBox(height: 10),
          Text(
            restaurant.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff666666),
              height: 1.4, // Line height equivalent
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Location Button
              GestureDetector(
                onTap: () {
                  final lat = restaurant.address.coordinates.lat;
                  final lng = restaurant.address.coordinates.lng;
                  openMaps(lat, lng, label: restaurant.name);
                },
                child: const Icon(
                  Icons
                      .location_on, // Equivalent to Ionicons name="location-sharp"
                  size: 24,
                  color: Colors.green,
                ),
              ),
              // Rating
              Text(
                '⭐ ${restaurant.averageRating.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 14, color: Color(0xff666666)),
              ),
              // Delivery Time
              Text(
                '🕒 ${restaurant.estimatedDeliveryTime}',
                style: const TextStyle(fontSize: 14, color: Color(0xff666666)),
              ),
              // Distance (Hardcoded in RN code)
              const Text(
                '🚴 2.5 km',
                style: TextStyle(fontSize: 14, color: Color(0xff666666)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
