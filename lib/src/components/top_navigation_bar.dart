import 'package:flutter/material.dart';

class TopNavigationBar extends StatelessWidget {
  final Function(String) onSearch;
  final VoidCallback onProfilePress;
  final VoidCallback onCartPress;
  final int cartItemsCount;

  const TopNavigationBar({
    super.key,
    required this.onSearch,
    required this.onProfilePress,
    required this.onCartPress,
    this.cartItemsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87, size: 26),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),

          const SizedBox(width: 8),
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, size: 20, color: Color(0xFF666666)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search for food...',
                        hintStyle: TextStyle(color: Color(0xFF999999)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      onChanged: onSearch,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Profile Icon
          IconButton(
            onPressed: onProfilePress,
            icon: const Icon(
              Icons.person_outline,
              size: 24,
              color: Colors.black87,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),

          // Cart Icon with Badge
          Stack(
            children: [
              IconButton(
                onPressed: onCartPress,
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 24,
                  color: Colors.black87,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              if (cartItemsCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cartItemsCount > 9 ? '9+' : cartItemsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
