import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../context/cart_provider.dart';
import '../screens/cart_screen.dart';
import '../navigation/main_navigator.dart';

class CartFooter extends StatelessWidget {
  const CartFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final totalItems = cartProvider.getTotalItemsCount();
    final totalAmount = _calculateTotalAmount(cartProvider);

    // Don't show the footer if cart is empty (same as React Native)
    if (totalItems == 0) return const SizedBox.shrink();

    return Positioned(
      bottom: 15,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E8B57), // same as #2E8B57

          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                // Navigate to cart screen
                MainNavigator.switchToTab(4);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      'View Cart',
                      style: TextStyle(
                        color: const Color(0xFF2E8B57),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: const Color(0xFF2E8B57),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalAmount(CartProvider cartProvider) {
    double total = 0.0;
    for (final restaurantId in cartProvider.carts.keys) {
      total += cartProvider.getCartTotal(restaurantId);
    }
    return total;
  }
}
