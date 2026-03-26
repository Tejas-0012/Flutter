// lib/src/models/menu_item.dart
class MenuItem {
  final String menuItemId;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String category;
  final String subCategory;
  final DietaryInfo dietaryInfo;
  final List<String>? climateTags;
  final List<String>? seasonalSuitable;
  final List<String> mealContext;
  final bool isAvailable;
  final int preparationTime;
  final List<String> images;
  final double popularity;
  final double rating;
  final int ratingCount;
  final int displayOrder;
  final List<String>? ingredients;
  final List<CustomizationOption>? customizationOptions;
  final int? maxQuantity;
  final bool? isRecommended;
  final Discount? discount;
  final NutritionalInfo? nutritionalInfo;

  MenuItem({
    required this.menuItemId,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.subCategory,
    required this.dietaryInfo,
    required this.climateTags,
    required this.seasonalSuitable,
    required this.mealContext,
    required this.isAvailable,
    required this.preparationTime,
    required this.images,
    required this.popularity,
    required this.rating,
    required this.ratingCount,
    required this.displayOrder,

    this.ingredients,
    this.customizationOptions,
    this.maxQuantity,
    this.isRecommended,
    this.discount,
    this.nutritionalInfo,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      menuItemId: json['menuItemId'],
      restaurantId: json['restaurantId'],
      name: json['name'],
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      category: json['category'],
      subCategory: json['subCategory'],
      dietaryInfo: DietaryInfo.fromJson(json['dietaryInfo']),
      climateTags: List<String>.from(json['climateTags'] ?? []),
      seasonalSuitable: List<String>.from(json['seasonalSuitable'] ?? ['all']),
      mealContext: List<String>.from(json['mealContext'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      preparationTime: json['preparationTime'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      popularity: json['popularity']?.toDouble() ?? 0.0,
      rating: json['rating']?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      displayOrder: json['displayOrder'] ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      customizationOptions: json['customizationOptions'] != null
          ? List<CustomizationOption>.from(
              json['customizationOptions'].map(
                (x) => CustomizationOption.fromJson(x),
              ),
            )
          : null,
      maxQuantity: json['maxQuantity'],
      isRecommended: json['isRecommended'],
      discount: json['discount'] != null
          ? Discount.fromJson(json['discount'])
          : null,
      nutritionalInfo: json['nutritionalInfo'] != null
          ? NutritionalInfo.fromJson(json['nutritionalInfo'])
          : null,
    );
  }
}

class DietaryInfo {
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final bool isNutFree;
  final bool isSpicy;
  final int spiceLevel;
  final int calories;
  final List<String> allergens;
  final List<String> tags;

  DietaryInfo({
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.isDairyFree,
    required this.isNutFree,
    required this.isSpicy,
    required this.spiceLevel,
    required this.calories,
    required this.allergens,
    required this.tags,
  });

  factory DietaryInfo.fromJson(Map<String, dynamic> json) {
    return DietaryInfo(
      isVegetarian: json['isVegetarian'] ?? false,
      isVegan: json['isVegan'] ?? false,
      isGlutenFree: json['isGlutenFree'] ?? false,
      isDairyFree: json['isDairyFree'] ?? false,
      isNutFree: json['isNutFree'] ?? false,
      isSpicy: json['isSpicy'] ?? false,
      spiceLevel: json['spiceLevel'] ?? 0,
      calories: json['calories'] ?? 0,
      allergens: List<String>.from(json['allergens'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class CustomizationOption {
  final String name;
  final List<Choice> choices;

  CustomizationOption({required this.name, required this.choices});

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      name: json['name'],
      choices: List<Choice>.from(
        json['choices'].map((x) => Choice.fromJson(x)),
      ),
    );
  }
}

class Choice {
  final String name;
  final double price;

  Choice({required this.name, required this.price});

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(name: json['name'], price: json['price']?.toDouble() ?? 0.0);
  }
}

class Discount {
  final String type;
  final double value;
  final DateTime? validUntil;

  Discount({required this.type, required this.value, this.validUntil});

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      type: json['type'],
      value: json['value']?.toDouble() ?? 0.0,
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
    );
  }
}

class NutritionalInfo {
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  NutritionalInfo({
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    return NutritionalInfo(
      protein: json['protein']?.toDouble(),
      carbs: json['carbs']?.toDouble(),
      fat: json['fat']?.toDouble(),
      fiber: json['fiber']?.toDouble(),
      sugar: json['sugar']?.toDouble(),
      sodium: json['sodium']?.toDouble(),
    );
  }
}

class RestaurantCoords {
  final double lat;
  final double lng;

  RestaurantCoords({required this.lat, required this.lng});
}
