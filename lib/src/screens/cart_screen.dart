import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../context/cart_provider.dart';
import 'delivery_screen.dart';
import '../context/voice_state.dart';
import '../utils/voice_command_processor.dart';
import '../screens/voice_assistant.dart';
import 'payment_screen.dart';
import '../navigation/main_navigator.dart';
import '../../widgets/voice_listening_overlay.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool showDeliveryModal = false;
  List<Map<String, dynamic>> activeDeliveries = [];
  final VoiceAssistant _voiceAssistant = VoiceAssistant();

  @override
  void initState() {
    super.initState();
    // Load active deliveries from storage
    _loadActiveDeliveries();
    _setupVoiceAssistant();
  }

  void _setupVoiceAssistant() {
    _voiceAssistant.setScreenContext('cart');
    _voiceAssistant.setCallbacks(
      onCommandDetected: (command) {
        if (mounted) {
          _handleVoiceCommand(command);
        }
      },
      onListeningStateChanged: (listening) {
        if (mounted) {
          final voiceState = Provider.of<VoiceState>(context, listen: false);
          voiceState.setListeningState(listening);
        }
      },
    );
  }

  void _handleVoiceCommand(String command) {
    final voiceState = Provider.of<VoiceState>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final processed = VoiceCommandProcessor.processCommand(command, 'cart');

    print("🎯 Cart voice command: '$command' -> ${processed['command']}");

    switch (processed['command']) {
      case 'remove_from_cart':
        final itemName = processed['data'] as String;
        _handleVoiceRemoveItem(itemName, cartProvider);
        voiceState.updateCommandResult(
          'remove_from_cart',
          'Removing $itemName',
        );
        break;

      case 'checkout':
        _handleVoiceCheckout(cartProvider);
        voiceState.updateCommandResult('checkout', 'Processing checkout');
        break;

      case 'clear_cart':
        _handleVoiceClearCart(cartProvider);
        voiceState.updateCommandResult('clear_cart', 'Cart cleared');
        break;

      case 'home':
        _handleVoiceNavigateHome();
        voiceState.updateCommandResult('home', 'Going home');
        break;

      case 'back':
        _handleVoiceNavigateBack();
        voiceState.updateCommandResult('back', 'Going back');
        break;

      case 'query_cart':
        _handleVoiceQueryCart(cartProvider);
        voiceState.updateCommandResult('query_cart', 'Cart contents read');
        break;

      case 'increase_quantity':
        final itemName = processed['data'] as String;
        _handleVoiceIncreaseQuantity(itemName, cartProvider);
        voiceState.updateCommandResult(
          'increase_quantity',
          'Increasing $itemName',
        );
        break;

      case 'decrease_quantity':
        final itemName = processed['data'] as String;
        _handleVoiceDecreaseQuantity(itemName, cartProvider);
        voiceState.updateCommandResult(
          'decrease_quantity',
          'Decreasing $itemName',
        );
        break;

      case 'total_amount':
        _handleVoiceTotalAmount(cartProvider);
        voiceState.updateCommandResult('total_amount', 'Reading total amount');
        break;

      case 'delivery_info':
        _handleVoiceDeliveryInfo(cartProvider);
        voiceState.updateCommandResult('delivery_info', 'Delivery information');
        break;

      case 'help':
        _handleVoiceHelp();
        voiceState.updateCommandResult('help', 'Help information');
        break;

      default:
        _voiceAssistant.speak(
          "Sorry, I didn't understand that cart command. Try: remove item, checkout, or what's in my cart?",
        );
    }
  }

  // 🆕 VOICE HANDLER METHODS
  void _handleVoiceRemoveItem(String itemName, CartProvider cartProvider) {
    bool itemFound = false;

    for (final restaurantCart in cartProvider.carts.values) {
      for (final item in restaurantCart.items) {
        if (_fuzzyMatch(item.name, itemName)) {
          cartProvider.removeFromCart(item.restaurantId, item.menuItemId);
          _voiceAssistant.speak("Removed $itemName from cart");
          itemFound = true;
          break;
        }
      }
      if (itemFound) break;
    }

    if (!itemFound) {
      _voiceAssistant.speak("Could not find $itemName in your cart");
    }
  }

  void _handleVoiceIncreaseQuantity(
    String itemName,
    CartProvider cartProvider,
  ) {
    bool itemFound = false;

    for (final restaurantCart in cartProvider.carts.values) {
      for (final item in restaurantCart.items) {
        if (_fuzzyMatch(item.name, itemName)) {
          // Add one more of the same item
          cartProvider.addToCart(
            item.restaurantId,
            restaurantCart.restaurantName,
            item,
            restaurantCoords: restaurantCart.restaurantCoords,
          );
          _voiceAssistant.speak("Increased quantity of $itemName");
          itemFound = true;
          break;
        }
      }
      if (itemFound) break;
    }

    if (!itemFound) {
      _voiceAssistant.speak("Could not find $itemName in your cart");
    }
  }

  void _handleVoiceDecreaseQuantity(
    String itemName,
    CartProvider cartProvider,
  ) {
    bool itemFound = false;

    for (final restaurantCart in cartProvider.carts.values) {
      for (final item in restaurantCart.items) {
        if (_fuzzyMatch(item.name, itemName)) {
          if (item.quantity > 1) {
            cartProvider.removeFromCart(item.restaurantId, item.menuItemId);
            _voiceAssistant.speak("Decreased quantity of $itemName");
          } else {
            _voiceAssistant.speak(
              "$itemName has only one quantity. Say remove to delete it completely",
            );
          }
          itemFound = true;
          break;
        }
      }
      if (itemFound) break;
    }

    if (!itemFound) {
      _voiceAssistant.speak("Could not find $itemName in your cart");
    }
  }

  void _handleVoiceCheckout(CartProvider cartProvider) {
    if (cartProvider.carts.isEmpty) {
      _voiceAssistant.speak("Your cart is empty");
      return;
    }

    // Process checkout for first restaurant
    final restaurantId = cartProvider.carts.keys.first;
    final restaurantCart = cartProvider.carts[restaurantId]!;
    final total = cartProvider.getCartTotal(restaurantId);
    final deliveryFee = total > 500 ? 0 : 40;
    final finalAmount = total + deliveryFee;

    // 🆕 DIRECT NAVIGATION TO PAYMENT SCREEN
    _navigateToPaymentScreen(
      restaurantId,
      restaurantCart.restaurantName,
      finalAmount,
      restaurantCart.restaurantCoords,
    );

    _voiceAssistant.speak(
      "Navigating to payment for ${restaurantCart.restaurantName}. Total amount is ${finalAmount.toStringAsFixed(2)} rupees",
    );
  }

  // 🆕 ADD THIS HELPER METHOD FOR DIRECT NAVIGATION
  void _navigateToPaymentScreen(
    String restaurantId,
    String restaurantName,
    double amount,
    RestaurantCoords? restaurantCoords,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            amount: amount,
            restaurantCoords: restaurantCoords,
          ),
        ),
      );
    });
  }

  void _handleVoiceClearCart(CartProvider cartProvider) {
    if (cartProvider.carts.isEmpty) {
      _voiceAssistant.speak("Your cart is already empty");
      return;
    }

    int totalItems = cartProvider.getTotalItemsCount();

    for (final restaurantId in cartProvider.carts.keys) {
      cartProvider.clearCart(restaurantId);
    }

    _voiceAssistant.speak("Cart cleared. Removed $totalItems items");
  }

  void _handleVoiceQueryCart(CartProvider cartProvider) {
    final totalItems = cartProvider.getTotalItemsCount();

    if (totalItems == 0) {
      _voiceAssistant.speak("Your cart is empty");
      return;
    }

    // 🆕 COLLECT ITEM DETAILS
    List<String> itemDescriptions = [];
    double totalAmount = 0;

    for (final restaurantCart in cartProvider.carts.values) {
      for (final item in restaurantCart.items) {
        // Format: "2 Masala Dosa at 80 rupees each"
        String itemDesc = "${item.quantity} ${item.name}";
        if (item.quantity > 1) {
          itemDesc += " at ${item.price} rupees each";
        }
        itemDescriptions.add(itemDesc);
        totalAmount += (item.price * item.quantity);
      }
    }

    final deliveryFee = totalAmount > 500 ? 0 : 40;
    final finalAmount = totalAmount + deliveryFee;

    // 🆕 BUILD DETAILED MESSAGE
    String message = "Your cart has: ";
    message += itemDescriptions.join(', ');
    message += ". Subtotal is ${totalAmount.toStringAsFixed(2)} rupees. ";
    message += deliveryFee == 0
        ? "Delivery is free. "
        : "Delivery fee is $deliveryFee rupees. ";
    message += "Total amount is ${finalAmount.toStringAsFixed(2)} rupees.";

    _voiceAssistant.speak(message);
  }

  void _handleVoiceTotalAmount(CartProvider cartProvider) {
    double totalAmount = 0;
    for (final restaurantId in cartProvider.carts.keys) {
      totalAmount += cartProvider.getCartTotal(restaurantId);
    }

    final deliveryFee = totalAmount > 500 ? 0 : 40;
    final finalAmount = totalAmount + deliveryFee;

    _voiceAssistant.speak(
      "Your total amount is ${finalAmount.toStringAsFixed(2)} rupees",
    );
  }

  void _handleVoiceDeliveryInfo(CartProvider cartProvider) {
    double totalAmount = 0;
    for (final restaurantId in cartProvider.carts.keys) {
      totalAmount += cartProvider.getCartTotal(restaurantId);
    }

    final deliveryFee = totalAmount > 500 ? 0 : 40;

    final message = deliveryFee == 0
        ? "Delivery is free for orders above 500 rupees. Your order qualifies for free delivery!"
        : "Delivery fee is 40 rupees. Add items worth ${(500 - totalAmount).toStringAsFixed(2)} more rupees for free delivery";

    _voiceAssistant.speak(message);
  }

  void _handleVoiceNavigateHome() {
    _voiceAssistant.speak("Going home");
    MainNavigator.switchToTab(0);
  }

  void _handleVoiceNavigateBack() {
    _voiceAssistant.speak("Going back");
    Navigator.pop(context);
  }

  void _handleVoiceHelp() {
    _voiceAssistant.speak(
      "You can say: remove item name, increase item, decrease item, checkout, "
      "clear cart, what's in my cart, total amount, delivery info, go back, or go home",
    );
  }

  // 🆕 FUZZY MATCHING FOR BETTER VOICE RECOGNITION
  bool _fuzzyMatch(String itemName, String searchTerm) {
    final itemWords = itemName.toLowerCase().split(' ');
    final searchWords = searchTerm.toLowerCase().split(' ');

    return searchWords.every(
      (searchWord) => itemWords.any(
        (itemWord) =>
            itemWord.contains(searchWord) || searchWord.contains(itemWord),
      ),
    );
  }

  @override
  void dispose() {
    _voiceAssistant.dispose();
    super.dispose();
  }

  void _loadActiveDeliveries() async {
    // You can load from SharedPreferences here
    // final prefs = await SharedPreferences.getInstance();
    // final savedDeliveries = prefs.getString('activeDeliveries');
    // if (savedDeliveries != null) {
    //   setState(() {
    //     activeDeliveries = List<Map<String, dynamic>>.from(json.decode(savedDeliveries));
    //   });
    // }
  }

  void _saveActiveDeliveries() async {
    // Save to SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('activeDeliveries', json.encode(activeDeliveries));
  }

  // ❌ Remove one item
  void _removeItem(
    String restaurantId,
    String menuItemId,
    CartProvider cartProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remove Item"),
          content: const Text("Are you sure you want to remove this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                cartProvider.removeFromCart(restaurantId, menuItemId);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );
  }

  // 💳 Checkout for each restaurant
  // 💳 Checkout for each restaurant - REPLACE THIS METHOD
  void _handleCheckout(
    String restaurantId,
    double amount,
    CartProvider cartProvider,
  ) {
    final restaurantCart = cartProvider.carts[restaurantId];
    final restaurantName = restaurantCart?.restaurantName ?? 'Restaurant';
    final restaurantCoords = restaurantCart?.restaurantCoords;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Proceed to Checkout"),
          content: Text(
            "Pay ₹${amount.toStringAsFixed(2)} for ${restaurantCart?.restaurantName}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to Payment Screen instead of showing order placed dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      restaurantId: restaurantId,
                      restaurantName: restaurantName,
                      amount: amount,
                      restaurantCoords: restaurantCoords,
                    ),
                  ),
                );
              },
              child: const Text("Proceed to Pay"),
            ),
          ],
        );
      },
    );
  }

  // Get the first active delivery for tracking
  Map<String, dynamic>? get _currentDelivery {
    return activeDeliveries.isNotEmpty ? activeDeliveries[0] : null;
  }

  // Remove a delivery when it's completed
  void _completeDelivery(String restaurantId) {
    setState(() {
      activeDeliveries = activeDeliveries
          .where((delivery) => delivery['restaurantId'] != restaurantId)
          .toList();
    });
    _saveActiveDeliveries();
  }

  // 🛍️ Render each item
  Widget _buildCartItem(
    CartItem item,
    String restaurantName,
    CartProvider cartProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (item.dietaryInfo?.tags != null &&
                    item.dietaryInfo!.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: item.dietaryInfo!.tags.take(2).map<Widget>((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEAEA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: item.quantity == 1
                          ? Colors.grey
                          : const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: 28,
                    height: 28,
                    child: IconButton(
                      onPressed: item.quantity == 1
                          ? null
                          : () => cartProvider.removeFromCart(
                              item.restaurantId,
                              item.menuItemId,
                            ),
                      icon: const Icon(
                        Icons.remove,
                        size: 16,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: 28,
                    height: 28,
                    child: IconButton(
                      onPressed: () => cartProvider.addToCart(
                        item.restaurantId,
                        restaurantName,
                        item,
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () => _removeItem(
                  item.restaurantId,
                  item.menuItemId,
                  cartProvider,
                ),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(0xFFFF6B6B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final restaurantCarts = cartProvider.carts;

    return Consumer<VoiceState>(
      builder: (context, voiceState, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () =>
                  MainNavigator.switchToTab(0), // ⬅️ Go back to previous screen
            ),
            title: const Text(
              'Your Cart',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Show tracking button only when there are active deliveries
                      if (activeDeliveries.isNotEmpty)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Track Your Order (${activeDeliveries.length} active)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (restaurantCarts.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your cart is empty',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add some delicious food to get started!',
                                  style: TextStyle(color: Color(0xFF999999)),
                                ),
                                const SizedBox(height: 16),
                                // Add voice help tip
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E8B57),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '💡 Say "Hey Platter, add [item] to cart" from menu screen',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Your Cart',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: restaurantCarts.keys.length,
                                  itemBuilder: (context, index) {
                                    final restaurantId = restaurantCarts.keys
                                        .elementAt(index);
                                    final restaurantCart =
                                        restaurantCarts[restaurantId]!;
                                    final items = restaurantCart.items;
                                    final restaurantName =
                                        restaurantCart.restaurantName;
                                    final total = items.fold(
                                      0.0,
                                      (sum, item) =>
                                          sum + (item.price * item.quantity),
                                    );
                                    final deliveryFee = total > 500 ? 0 : 40;
                                    final finalAmount = total + deliveryFee;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 2,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Restaurant Header
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: Text(
                                              restaurantName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),

                                          // Cart Items
                                          ...items.map(
                                            (item) => _buildCartItem(
                                              item,
                                              restaurantName,
                                              cartProvider,
                                            ),
                                          ),

                                          // Summary
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Subtotal',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      '₹${total.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Delivery Fee',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      deliveryFee == 0
                                                          ? "FREE"
                                                          : "₹$deliveryFee",
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(
                                                        color:
                                                            Colors.grey[400]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'Total',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        '₹${finalAmount.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFFFF6B6B,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        _handleCheckout(
                                                          restaurantId,
                                                          finalAmount,
                                                          cartProvider,
                                                        ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFFF6B6B,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Checkout for $restaurantName',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
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
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // VOICE LISTENING OVERLAY
              if (voiceState.isListening)
                VoiceListeningOverlay(
                  onClose: () {
                    final voiceState = Provider.of<VoiceState>(
                      context,
                      listen: false,
                    );
                    voiceState.setListeningState(false);
                  },
                  screenContext:
                      'cart', // Pass cart context for relevant commands
                ),

              // 🚚 Delivery tracking modal
              if (showDeliveryModal && _currentDelivery != null)
                DeliveryTrackingScreen(
                  restaurantCoords: _currentDelivery!['coords'],
                  restaurantName: _currentDelivery!['restaurantName'],
                  orderId:
                      _currentDelivery!['orderId'] ??
                      'ORD${DateTime.now().millisecondsSinceEpoch}',
                  deliveryPartnerName:
                      _currentDelivery!['deliveryPartnerName'] ??
                      'Delivery Partner',
                  deliveryPartnerPhone:
                      _currentDelivery!['deliveryPartnerPhone'] ??
                      '+1234567890',
                ),
            ],
          ),
        );
      },
    );
  }
}
