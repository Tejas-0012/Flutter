import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeliveryTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> restaurantCoords;
  final String restaurantName;
  final String orderId;
  final String deliveryPartnerName;
  final String deliveryPartnerPhone;

  const DeliveryTrackingScreen({
    super.key,
    required this.restaurantCoords,
    required this.restaurantName,
    required this.orderId,
    required this.deliveryPartnerName,
    required this.deliveryPartnerPhone,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen>
    with TickerProviderStateMixin {
  final String googleMapsApiKey = "AIzaSyAs3LsAByOa-56OfqKYBbq9FaQsZB09Mzs";

  late GoogleMapController mapController;
  Position? userPosition;
  bool loading = true;
  int progress = 0;
  int eta = 0;
  bool deliveryCompleted = false;

  // Markers
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  // Delivery marker position (animated)
  LatLng deliveryPosition = const LatLng(0, 0);

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;

  // Delivery stages
  final List<DeliveryStage> deliveryStages = [
    DeliveryStage('Order Confirmed', Icons.check_circle, 0),
    DeliveryStage('Food Preparing', Icons.restaurant, 25),
    DeliveryStage('Out for Delivery', Icons.delivery_dining, 50),
    DeliveryStage('Almost There', Icons.location_on, 75),
    DeliveryStage('Delivered', Icons.celebration, 100),
  ];

  int currentStageIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentStage();
  }

  void _updateCurrentStage() {
    for (int i = deliveryStages.length - 1; i >= 0; i--) {
      if (progress >= deliveryStages[i].progress) {
        setState(() {
          currentStageIndex = i;
        });
        break;
      }
    }
  }

  void _initializeData() async {
    await _getUserLocation();
    await _calculateRoute();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showLocationError('Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        userPosition = position;
      });
    } catch (e) {
      print('Geolocation error: $e');
      _showLocationError('Failed to get location: $e');
    }
  }

  void _showLocationError(String message) {
    // Fallback to default location near restaurant
    setState(() {
      userPosition = Position(
        longitude: 12.963059,
        latitude: 77.505912,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _calculateRoute() async {
    if (userPosition == null) {
      debugPrint("User position not available");
      return;
    }

    final restaurantLatLng = LatLng(
      widget.restaurantCoords['latitude'],
      widget.restaurantCoords['longitude'],
    );

    final userLatLng = LatLng(userPosition!.latitude, userPosition!.longitude);

    // Initialize delivery position at restaurant
    setState(() {
      deliveryPosition = restaurantLatLng;
    });

    try {
      debugPrint("Calculating route from restaurant to user");
      debugPrint(
        "Restaurant: ${restaurantLatLng.latitude}, ${restaurantLatLng.longitude}",
      );
      debugPrint("User: ${userLatLng.latitude}, ${userLatLng.longitude}");

      await _createRoute(restaurantLatLng, userLatLng);

      if (polylines.isNotEmpty) {
        final estimatedEta = _calculateETA(polylines.first.points);
        setState(() {
          eta = estimatedEta;
        });
        debugPrint("Route calculated successfully. ETA: $eta minutes");

        _startDeliveryAnimation(polylines.first.points);
      } else {
        debugPrint("No polylines created");
        _showRoutingError();
      }
    } catch (e) {
      debugPrint('Route calculation error: $e');
      _showRoutingError();
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  int _calculateETA(List<LatLng> coordinates) {
    if (coordinates.length < 2) return 15;

    double totalDistance = 0;
    for (int i = 1; i < coordinates.length; i++) {
      totalDistance += _calculateDistance(
        coordinates[i - 1].latitude,
        coordinates[i - 1].longitude,
        coordinates[i].latitude,
        coordinates[i].longitude,
      );
    }

    // Assume average speed of 30 km/h in urban areas
    double timeInHours = totalDistance / 30;
    return (timeInHours * 60).ceil().clamp(5, 60);
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // NEW: SIMPLE ROUTE CREATION THAT WORKS
  Future<void> _createRoute(LatLng origin, LatLng destination) async {
    try {
      // For web, use our smart route generator
      if (kIsWeb) {
        await _createSmartRoute(origin, destination);
      } else {
        // For mobile, try direct API call
        await _fetchDirectionsDirect(origin, destination);
      }
    } catch (e) {
      debugPrint("Route creation failed: $e");
      // Always fallback to smart route
      _createSmartRoute(origin, destination);
    }
  }

  // NEW: SMART ROUTE GENERATOR (No API needed)
  Future<void> _createSmartRoute(LatLng origin, LatLng destination) async {
    debugPrint(
      "Creating smart route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}",
    );

    final List<LatLng> points = [];
    points.add(origin);

    // Calculate differences
    final double latDiff = destination.latitude - origin.latitude;
    final double lngDiff = destination.longitude - origin.longitude;

    // Calculate distance for number of segments
    final double distance = _calculateDistance(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    // More segments for longer distances
    final int segments = (distance * 100).ceil().clamp(10, 50);
    debugPrint(
      "Creating route with $segments segments for ${distance.toStringAsFixed(2)} km",
    );

    // Create realistic road-like path with curves
    for (int i = 1; i < segments; i++) {
      final double factor = i / segments;

      // Create road-like curvature using sine waves
      final double roadCurve = sin(factor * pi * 2) * 0.0005;
      final double secondaryCurve = cos(factor * pi * 3) * 0.0002;

      // Add some randomness to simulate actual roads
      final double randomVariation = (Random().nextDouble() - 0.5) * 0.0001;

      points.add(
        LatLng(
          origin.latitude + (latDiff * factor) + roadCurve + secondaryCurve,
          origin.longitude +
              (lngDiff * factor) +
              roadCurve -
              secondaryCurve +
              randomVariation,
        ),
      );
    }

    points.add(destination);

    setState(() {
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('smart_route'),
          points: points,
          color: Colors.blue,
          width: 5,
        ),
      );
    });

    debugPrint("Smart route created with ${points.length} points");
  }

  // NEW: DIRECT API CALL (for mobile)
  Future<void> _fetchDirectionsDirect(LatLng origin, LatLng destination) async {
    const apiKey = "AIzaSyAs3LsAByOa-56OfqKYBbq9FaQsZB09Mzs";
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&key=$apiKey"
        "&mode=driving";

    debugPrint("Fetching directions directly from API");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Directions API response: ${data['status']}");

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> polylinePoints = _decodePolyline(points);

          debugPrint("Route decoded with ${polylinePoints.length} points");

          setState(() {
            polylines.clear();
            polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePoints,
                color: Colors.green,
                width: 5,
              ),
            );
          });
        } else {
          debugPrint("No routes found: ${data['status']}");
          throw Exception('No routes available: ${data['status']}');
        }
      } else {
        debugPrint("HTTP error: ${response.statusCode}");
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Direct API call failed: $e");
      rethrow;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _startDeliveryAnimation(List<LatLng> coordinates) {
    if (coordinates.isEmpty) return;

    final tween = Tween<double>(begin: 0, end: 1);
    final animation = tween.animate(_animationController);

    _animationController.addListener(() {
      final value = animation.value;
      final index = (value * (coordinates.length - 1))
          .clamp(0, coordinates.length - 1)
          .toInt();
      final nextIndex = (index + 1).clamp(0, coordinates.length - 1);
      final progressValue = value * (coordinates.length - 1) - index;

      // Interpolate between points for smooth animation
      final currentPoint = coordinates[index];
      final nextPoint = coordinates[nextIndex];

      setState(() {
        deliveryPosition = LatLng(
          currentPoint.latitude +
              (nextPoint.latitude - currentPoint.latitude) * progressValue,
          currentPoint.longitude +
              (nextPoint.longitude - currentPoint.longitude) * progressValue,
        );
        progress = (value * 100).round();
        _updateCurrentStage();
      });
    });

    _animationController.forward().then((_) {
      _handleDeliveryComplete();
    });
  }

  void _handleDeliveryComplete() {
    setState(() {
      progress = 100;
      deliveryCompleted = true;
      _updateCurrentStage();
    });

    _pulseAnimationController.stop();

    // Show delivery complete dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delivery Complete! 🎉"),
            content: const Text("Your food has arrived! Enjoy your meal!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Great!"),
              ),
            ],
          );
        },
      );
    }
  }

  void _showRoutingError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Using simulated route for delivery tracking'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  LatLngBounds _getBounds() {
    if (userPosition == null) {
      return LatLngBounds(
        southwest: LatLng(
          widget.restaurantCoords['latitude'] - 0.05,
          widget.restaurantCoords['longitude'] - 0.05,
        ),
        northeast: LatLng(
          widget.restaurantCoords['latitude'] + 0.05,
          widget.restaurantCoords['longitude'] + 0.05,
        ),
      );
    }

    final restaurantLatLng = LatLng(
      widget.restaurantCoords['latitude'],
      widget.restaurantCoords['longitude'],
    );

    final userLatLng = LatLng(userPosition!.latitude, userPosition!.longitude);

    return LatLngBounds(
      southwest: LatLng(
        min(restaurantLatLng.latitude, userLatLng.latitude) - 0.01,
        min(restaurantLatLng.longitude, userLatLng.longitude) - 0.01,
      ),
      northeast: LatLng(
        max(restaurantLatLng.latitude, userLatLng.latitude) + 0.01,
        max(restaurantLatLng.longitude, userLatLng.longitude) + 0.01,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantLatLng = LatLng(
      widget.restaurantCoords['latitude'],
      widget.restaurantCoords['longitude'],
    );

    // Update markers
    markers.clear();

    // Restaurant marker
    markers.add(
      Marker(
        markerId: const MarkerId('restaurant'),
        position: restaurantLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.restaurantName),
      ),
    );

    // User marker
    if (userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(userPosition!.latitude, userPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Delivery marker
    markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: deliveryPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '${widget.deliveryPartnerName} - Delivery Partner',
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Map Section
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        mapController.animateCamera(
                          CameraUpdate.newLatLngBounds(_getBounds(), 100),
                        );
                      }
                    });
                  },
                  initialCameraPosition: CameraPosition(
                    target: restaurantLatLng,
                    zoom: 14,
                  ),
                  markers: markers,
                  polylines: polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // Delivery Info Card
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: _buildDeliveryInfoCard(),
                ),

                // Progress & ETA Card
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: _buildProgressCard(),
                ),

                // Loading overlay
                if (loading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFFFF6B6B),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Calculating best route...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 24),
          ),
          const SizedBox(width: 8),
          const Text(
            'Delivery Tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              _refreshTracking();
            },
            icon: const Icon(Icons.refresh, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.deliveryPartnerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Delivery Partner',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Call functionality
                  debugPrint('Calling ${widget.deliveryPartnerPhone}');
                },
                icon: const Icon(Icons.phone, color: Colors.green),
              ),
              IconButton(
                onPressed: () {
                  // Message functionality
                  debugPrint('Messaging ${widget.deliveryPartnerPhone}');
                },
                icon: const Icon(Icons.message, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order #${widget.orderId}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: deliveryCompleted
                      ? Colors.green
                      : const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Progress info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Progress: $progress%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'ETA: ${deliveryCompleted ? 'Arrived' : '$eta min'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: deliveryCompleted
                      ? Colors.green
                      : const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Delivery stages
          _buildDeliveryStages(),
        ],
      ),
    );
  }

  Widget _buildDeliveryStages() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: deliveryStages.length,
        itemBuilder: (context, index) {
          final stage = deliveryStages[index];
          final isCompleted = progress >= stage.progress;
          final isCurrent = index == currentStageIndex;

          return Container(
            margin: const EdgeInsets.only(right: 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (deliveryCompleted
                              ? Colors.green
                              : const Color(0xFFFF6B6B))
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: const Color(0xFFFF6B6B), width: 2)
                        : null,
                  ),
                  child: Icon(
                    stage.icon,
                    color: isCompleted ? Colors.white : Colors.grey[600],
                    size: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? (deliveryCompleted
                              ? Colors.green
                              : const Color(0xFFFF6B6B))
                        : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _refreshTracking() {
    setState(() {
      loading = true;
      progress = 0;
      deliveryCompleted = false;
    });

    _animationController.reset();
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    mapController.dispose();
    super.dispose();
  }
}

class DeliveryStage {
  final String title;
  final IconData icon;
  final int progress;

  DeliveryStage(this.title, this.icon, this.progress);
}
