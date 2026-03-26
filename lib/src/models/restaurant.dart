class Coordinates {
  final double lat;
  final double lng;

  Coordinates({required this.lat, required this.lng});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final Coordinates coordinates;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.coordinates,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      country: json['country'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
    );
  }
}

class Restaurant {
  final String id;
  final String name;
  final String cuisineType;
  final String description;
  final String image;
  final String logo;
  final double averageRating;
  final String estimatedDeliveryTime;
  final Address address;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisineType,
    required this.description,
    required this.image,
    required this.logo,
    required this.averageRating,
    required this.estimatedDeliveryTime,
    required this.address,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Restaurant',
      cuisineType: json['cuisineType'] ?? 'General',
      description: json['description'] ?? 'No description available.',
      image: json['image'] ?? '',
      logo: json['logo'] ?? '',
      averageRating: (json['rating']?['average'] as num?)?.toDouble() ?? 0.0,
      estimatedDeliveryTime: json['delivery']?['estimatedTime'] ?? '30 min',
      address: Address.fromJson(json['address'] ?? {}),
    );
  }
  factory Restaurant.empty() {
    return Restaurant(
      id: '',
      name: '',
      cuisineType: '',
      description: '',
      image: '',
      logo: '',
      averageRating: 0.0,
      estimatedDeliveryTime: '',
      address: Address(
        street: '',
        city: '',
        state: '',
        zipCode: '',
        country: '',
        coordinates: Coordinates(lat: 0.0, lng: 0.0),
      ),
    );
  }
}
