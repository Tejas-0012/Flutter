import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../context/group_cart_provider.dart';
import '../models/cart_item.dart';
import '../../widgets/cart_item_widget.dart';
import '../../widgets/chat_widget.dart';

class GroupCartScreen extends StatefulWidget {
  final String userId;
  final String username;

  const GroupCartScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  _GroupCartScreenState createState() => _GroupCartScreenState();
}

class _GroupCartScreenState extends State<GroupCartScreen> {
  final List<CartItem> _sampleItems = [
    CartItem(
      itemId: '1',
      name: 'Margherita Pizza',
      price: 12.99,
      quantity: 1,
      addedBy: '',
      addedByUsername: '',
    ),
    CartItem(
      itemId: '2',
      name: 'Pepperoni Pizza',
      price: 14.99,
      quantity: 1,
      addedBy: '',
      addedByUsername: '',
    ),
    CartItem(
      itemId: '3',
      name: 'Caesar Salad',
      price: 8.99,
      quantity: 1,
      addedBy: '',
      addedByUsername: '',
    ),
    CartItem(
      itemId: '4',
      name: 'Garlic Bread',
      price: 4.99,
      quantity: 1,
      addedBy: '',
      addedByUsername: '',
    ),
    CartItem(
      itemId: '5',
      name: 'Coca Cola',
      price: 2.99,
      quantity: 1,
      addedBy: '',
      addedByUsername: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupCartProvider>(
      builder: (context, provider, child) {
        final group = provider.currentGroup;
        if (group == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No active group'),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group: ${group.groupId}'),
                Text(
                  '${group.members.length} members • \$${provider.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: () {
                  provider.leaveGroup(widget.username);
                  Navigator.pop(context);
                },
                tooltip: 'Leave Group',
              ),
            ],
          ),
          body: Column(
            children: [
              // Members Section
              Container(
                padding: EdgeInsets.all(12),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Text('Members: '),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: group.members.map((member) {
                          return Chip(
                            label: Text(member.username),
                            backgroundColor: member.userId == group.createdBy
                                ? Colors.orange[100]
                                : null,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  children: [
                    // Items List & Add Items
                    Expanded(flex: 2, child: _buildItemsSection(provider)),

                    // Cart & Chat
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Cart Items
                          Expanded(flex: 2, child: _buildCartSection(provider)),

                          // Chat
                          Expanded(
                            flex: 1,
                            child: ChatWidget(
                              messages: provider.messages,
                              onSendMessage: (message) {
                                provider.sendMessage(
                                  widget.userId,
                                  widget.username,
                                  message,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Checkout Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${provider.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: provider.cartItems.isEmpty
                          ? null
                          : () => _showCheckoutDialog(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsSection(GroupCartProvider provider) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _sampleItems.length,
              itemBuilder: (context, index) {
                final item = _sampleItems[index];
                return ListTile(
                  leading: Icon(Icons.restaurant),
                  title: Text(item.name),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      provider.addItem(
                        CartItem(
                          itemId: item.itemId,
                          name: item.name,
                          price: item.price,
                          quantity: 1,
                          addedBy: widget.userId,
                          addedByUsername: widget.username,
                        ),
                        widget.userId,
                        widget.username,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection(GroupCartProvider provider) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Group Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: provider.cartItems.isEmpty
                ? Center(
                    child: Text(
                      'No items in cart\nStart adding items!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = provider.cartItems[index];
                      return CartItemWidget(
                        item: item,
                        isOwnItem: item.addedBy == widget.userId,
                        onIncrement: () {
                          provider.updateItemQuantity(
                            item.itemId,
                            widget.userId,
                            item.quantity + 1,
                          );
                        },
                        onDecrement: () {
                          if (item.quantity > 1) {
                            provider.updateItemQuantity(
                              item.itemId,
                              widget.userId,
                              item.quantity - 1,
                            );
                          } else {
                            provider.removeItem(item.itemId, widget.userId);
                          }
                        },
                        onRemove: () {
                          provider.removeItem(item.itemId, widget.userId);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(GroupCartProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Amount: \$${provider.totalAmount.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            Text('Items in cart:'),
            ...provider.cartItems.map(
              (item) => Text(
                '• ${item.name} x${item.quantity} - \$${(item.price * item.quantity).toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order placed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Confirm Order'),
          ),
        ],
      ),
    );
  }
}
