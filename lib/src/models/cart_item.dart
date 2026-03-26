class CartItem {
  final String itemId;
  final String name;
  final double price;
  int quantity;
  final String addedBy;
  final String addedByUsername;

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.addedBy,
    required this.addedByUsername,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: json['itemId'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      addedBy: json['addedBy'],
      addedByUsername: json['addedByUsername'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'addedBy': addedBy,
      'addedByUsername': addedByUsername,
    };
  }
}
