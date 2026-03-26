import 'package:flutter/material.dart';
import '../src/models/cart_item.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final bool isOwnItem;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.isOwnItem,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isOwnItem ? Colors.blue[50] : null,
      child: ListTile(
        leading: Icon(Icons.restaurant),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${item.price.toStringAsFixed(2)} each'),
            Text(
              'Added by: ${item.addedByUsername}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnItem) ...[
              IconButton(
                icon: Icon(Icons.remove, size: 20),
                onPressed: onDecrement,
                padding: EdgeInsets.zero,
              ),
              Text('${item.quantity}'),
              IconButton(
                icon: Icon(Icons.add, size: 20),
                onPressed: onIncrement,
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
              ),
            ] else ...[
              Text('${item.quantity}'),
              SizedBox(width: 8),
              Text(
                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
