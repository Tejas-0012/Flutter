import 'package:flutter/material.dart';
import '../models/menu_items.dart';
import 'package:provider/provider.dart';

// -------------------------
// TYPES
// -------------------------

class CartItem {
  final String menuItemId;
  final String restaurantId;
  final String name;
  final double price;
  final String? description;
  final String images;
  final DietaryInfo? dietaryInfo;
  int quantity;

  CartItem({
    required this.menuItemId,
    required this.restaurantId,
    required this.name,
    required this.price,
    this.description,
    this.images = "",
    this.dietaryInfo,
    required this.quantity,
  });

  CartItem.fromMenuItem(MenuItem item, {required this.quantity})
    : menuItemId = item.menuItemId,
      restaurantId = item.restaurantId,
      name = item.name,
      price = item.price,
      description = item.description,
      images = (item.images.isNotEmpty ? item.images.first : ""),
      dietaryInfo = item.dietaryInfo;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuItemId: menuItemId,
      restaurantId: restaurantId,
      name: name,
      price: price,
      description: description,
      images: images,
      quantity: quantity ?? this.quantity,
    );
  }
}

class RestaurantCoords {
  final double lat;
  final double lng;

  RestaurantCoords({required this.lat, required this.lng});

  factory RestaurantCoords.fromJson(Map<String, dynamic> json) {
    return RestaurantCoords(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}

class RestaurantCart {
  final String restaurantName;
  final RestaurantCoords? restaurantCoords;
  final List<CartItem> items;

  const RestaurantCart({
    required this.restaurantName,
    this.restaurantCoords,
    required this.items,
  });

  RestaurantCart copyWith({
    String? restaurantName,
    RestaurantCoords? restaurantCoords,
    List<CartItem>? items,
  }) {
    return RestaurantCart(
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantCoords: restaurantCoords ?? this.restaurantCoords,
      items: items ?? this.items,
    );
  }
}

// -------------------------
// PROVIDER
// -------------------------
class CartProvider extends ChangeNotifier {
  Map<String, RestaurantCart> _carts = {};

  Map<String, RestaurantCart> get carts => _carts;
  String? get activeRestaurantId {
    if (_carts.isEmpty) return null;
    return _carts.keys.first;
  }

  // -------------------------
  // ADD ITEM TO CART
  // -------------------------
  void addToCart(
    String restaurantId,
    String restaurantName,
    dynamic item, {
    RestaurantCoords? restaurantCoords,
  }) {
    // Get or create the restaurant cart
    final restaurantCart =
        _carts[restaurantId] ??
        RestaurantCart(
          restaurantName: restaurantName,
          restaurantCoords: restaurantCoords,
          items: [],
        );

    // Find existing item
    final existingItemIndex = restaurantCart.items.indexWhere(
      (i) => i.menuItemId == item.menuItemId,
    );

    List<CartItem> updatedItems;

    if (existingItemIndex != -1) {
      // Increment quantity if item exists
      updatedItems = List<CartItem>.from(restaurantCart.items);
      updatedItems[existingItemIndex] = updatedItems[existingItemIndex]
          .copyWith(quantity: updatedItems[existingItemIndex].quantity + 1);
    } else {
      // Add new item
      updatedItems = [
        ...restaurantCart.items,
        CartItem.fromMenuItem(item, quantity: 1),
      ];
    }

    // Update the cart map
    _carts = {
      ..._carts,
      restaurantId: RestaurantCart(
        restaurantName: restaurantName,
        restaurantCoords: restaurantCoords ?? restaurantCart.restaurantCoords,
        items: updatedItems,
      ),
    };

    notifyListeners();
  }

  // -------------------------
  // REMOVE ITEM (Decrease quantity by 1)
  // -------------------------
  void removeFromCart(String restaurantId, String menuItemId) {
    final restaurantCart = _carts[restaurantId];
    if (restaurantCart == null) return;

    final existingItemIndex = restaurantCart.items.indexWhere(
      (i) => i.menuItemId == menuItemId,
    );

    if (existingItemIndex == -1) return;

    List<CartItem> updatedItems = List<CartItem>.from(restaurantCart.items);
    final itemToRemove = updatedItems[existingItemIndex];

    if (itemToRemove.quantity > 1) {
      // Decrease quantity if greater than 1
      updatedItems[existingItemIndex] = itemToRemove.copyWith(
        quantity: itemToRemove.quantity - 1,
      );
    } else {
      // Remove item entirely if quantity is 1
      updatedItems.removeAt(existingItemIndex);
    }

    _carts = {
      ..._carts,
      restaurantId: restaurantCart.copyWith(items: updatedItems),
    };

    // Clear the whole restaurant cart if the item list is now empty
    if (updatedItems.isEmpty) {
      _carts.remove(restaurantId);
    }

    notifyListeners();
  }

  // -------------------------
  // CLEAR CART
  // -------------------------
  void clearCart(String restaurantId) {
    _carts.remove(restaurantId);
    notifyListeners();
  }

  // -------------------------
  // GET CART FOR A RESTAURANT
  // -------------------------
  List<CartItem> getCartForRestaurant(String restaurantId) {
    return _carts[restaurantId]?.items ?? [];
  }

  // -------------------------
  // GET TOTAL
  // -------------------------
  double getCartTotal(String restaurantId) {
    return getCartForRestaurant(
      restaurantId,
    ).fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // -------------------------
  // GET TOTAL ITEMS COUNT (Across all restaurants)
  // -------------------------
  int getTotalItemsCount() {
    return _carts.values.fold(
      0,
      (sum, restaurantCart) =>
          sum +
          restaurantCart.items.fold(
            0,
            (itemSum, item) => itemSum + item.quantity,
          ),
    );
  }

  // -------------------------
  // CHECK IF RESTAURANT HAS ITEMS
  // -------------------------
  bool hasItemsInRestaurant(String restaurantId) {
    return getCartForRestaurant(restaurantId).isNotEmpty;
  }

  // -------------------------
  // GET ITEM COUNT FOR RESTAURANT
  // -------------------------
  int getItemCountForRestaurant(String restaurantId) {
    return getCartForRestaurant(
      restaurantId,
    ).fold(0, (sum, item) => sum + item.quantity);
  }

  // -------------------------
  // REMOVE ITEM COMPLETELY (Remove regardless of quantity)
  // -------------------------
  void removeItemCompletely(String restaurantId, String menuItemId) {
    final restaurantCart = _carts[restaurantId];
    if (restaurantCart == null) return;

    final updatedItems = restaurantCart.items
        .where((item) => item.menuItemId != menuItemId)
        .toList();

    _carts = {
      ..._carts,
      restaurantId: restaurantCart.copyWith(items: updatedItems),
    };

    // Clear the whole restaurant cart if the item list is now empty
    if (updatedItems.isEmpty) {
      _carts.remove(restaurantId);
    }

    notifyListeners();
  }
}

// -------------------------
// PROVIDER EXTENSION FOR EASY ACCESS
// -------------------------
extension CartProviderExtension on BuildContext {
  CartProvider get cartProvider =>
      Provider.of<CartProvider>(this, listen: true);
}
