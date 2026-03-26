import 'package:flutter/material.dart';

class CustomDrawerContent extends StatelessWidget {
  const CustomDrawerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'label': 'Home', 'icon': Icons.home_outlined, 'route': '/home'},
      {'label': 'Profile', 'icon': Icons.person_outline, 'route': '/profile'},
      {'label': 'Cart', 'icon': Icons.shopping_cart_outlined, 'route': '/cart'},
      {
        'label': 'Orders',
        'icon': Icons.receipt_long_outlined,
        'route': '/orders',
      },
      {
        'label': 'Favorites',
        'icon': Icons.favorite_outline,
        'route': '/favorites',
      },
      {
        'label': 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
      },
    ];

    return Drawer(
      child: Column(
        children: [
          // 🟢 Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF4ECDC4),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white30,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            accountName: const Text(
              'John Doe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text('john.doe@example.com'),
          ),

          // 🟡 Menu List
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: Colors.black87,
                  ),
                  title: Text(
                    item['label'] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, item['route'] as String);
                  },
                );
              },
            ),
          ),

          // 🔴 Footer / Logout Button
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              // Implement logout logic here
            },
          ),
        ],
      ),
    );
  }
}
