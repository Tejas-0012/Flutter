import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../context/cart_provider.dart';
import '../context/voice_state.dart';
import '../../widgets/voice_listening_overlay.dart';
import 'voice_assistant.dart';
import '../utils/voice_command_processor.dart';
import 'delivery_screen.dart';
import 'real_qr_scanner_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final double amount;
  final RestaurantCoords? restaurantCoords;

  const PaymentScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.amount,
    this.restaurantCoords,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  final VoiceAssistant _voiceAssistant = VoiceAssistant();

  @override
  void initState() {
    super.initState();
    _setupVoiceAssistant();
  }

  void _setupVoiceAssistant() {
    _voiceAssistant.setScreenContext('payment');
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
    final processed = VoiceCommandProcessor.processCommand(command, 'payment');

    print("🎯 Payment voice command: '$command' -> ${processed['command']}");

    switch (processed['command']) {
      case 'make_payment':
        _handleVoiceMakePayment();
        voiceState.updateCommandResult('make_payment', 'Processing payment');
        break;

      case 'cancel_payment':
        _handleVoiceCancelPayment();
        voiceState.updateCommandResult('cancel_payment', 'Cancelling payment');
        break;

      case 'scan_qr':
        _handleVoiceScanQR();
        voiceState.updateCommandResult('scan_qr', 'Scanning QR code');
        break;

      case 'google_pay':
        _handleVoiceGooglePay();
        voiceState.updateCommandResult('google_pay', 'Google Pay selected');
        break;

      case 'card_payment':
        _handleVoiceCardPayment();
        voiceState.updateCommandResult('card_payment', 'Card payment selected');
        break;

      case 'cash_delivery':
        _handleVoiceCashDelivery();
        voiceState.updateCommandResult(
          'cash_delivery',
          'Cash on delivery selected',
        );
        break;

      case 'back':
        _handleVoiceNavigateBack();
        voiceState.updateCommandResult('back', 'Going back');
        break;

      case 'home':
        _handleVoiceNavigateHome();
        voiceState.updateCommandResult('home', 'Going home');
        break;

      case 'help':
        _handleVoiceHelp();
        voiceState.updateCommandResult('help', 'Showing help');
        break;

      default:
        _voiceAssistant.speak(
          "Sorry, I didn't understand that payment command. Try: pay now, cancel payment, or scan QR",
        );
    }
  }

  // 🆕 VOICE HANDLER METHODS
  void _handleVoiceMakePayment() {
    if (_isProcessing) {
      _voiceAssistant.speak("Payment is already being processed");
      return;
    }
    _voiceAssistant.speak(
      "Processing payment of ${_getTotalAmount().toStringAsFixed(2)} rupees",
    );
    _processPayment();
  }

  void _handleVoiceCancelPayment() {
    _voiceAssistant.speak("Cancelling payment and returning to cart");
    Navigator.pop(context);
  }

  void _handleVoiceScanQR() {
    _voiceAssistant.speak("Scanning QR code for payment");
    _processPayment();
  }

  void _handleVoiceGooglePay() {
    _voiceAssistant.speak("Opening Google Pay for payment");
    _showPaymentInfo('Google Pay');
  }

  void _handleVoiceCardPayment() {
    _voiceAssistant.speak("Processing card payment");
    _showPaymentInfo('Credit/Debit Card');
  }

  void _handleVoiceCashDelivery() {
    _voiceAssistant.speak(
      "Cash on delivery selected. You'll pay when food arrives",
    );
    _showPaymentInfo('Cash on Delivery');
  }

  void _handleVoiceNavigateBack() {
    _voiceAssistant.speak("Going back to cart");
    Navigator.pop(context);
  }

  void _handleVoiceNavigateHome() {
    _voiceAssistant.speak("Going home");
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _handleVoiceHelp() {
    _voiceAssistant.speak(
      "You can say: pay now, cancel payment, scan QR, Google Pay, card payment, "
      "cash on delivery, go back, or go home",
    );
  }

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Navigate to real QR scanner
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RealQRScannerScreen(
          restaurantName: widget.restaurantName,
          amount: widget.amount,
        ),
      ),
    );

    setState(() {
      _isProcessing = false;
    });

    if (success == true && mounted) {
      // ✅ Payment confirmed - proceed to delivery
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.clearCart(widget.restaurantId);

      // Navigate to delivery screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryTrackingScreen(
            restaurantCoords: widget.restaurantCoords != null
                ? {
                    'latitude': widget.restaurantCoords!.lat,
                    'longitude': widget.restaurantCoords!.lng,
                  }
                : {'latitude': 27.6129, 'longitude': 57.2295},
            restaurantName: widget.restaurantName,
            orderId: 'ORD${DateTime.now().millisecondsSinceEpoch}',
            deliveryPartnerName: 'Rahul Kumar',
            deliveryPartnerPhone: '+91 98765 43210',
          ),
        ),
      );
    } else if (success == false) {
      // ❌ Payment cancelled - show message
      _voiceAssistant.speak("Payment cancelled");
      _showCancellationMessage();
    } else {
      // User pressed back button - show info message
      _voiceAssistant.speak("Returned to payment options");
      _showBackButtonMessage();
    }
  }

  double _getTotalAmount() {
    return widget.amount + (widget.amount > 500 ? 0 : 40);
  }

  void _showCancellationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment cancelled'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showBackButtonMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Returned to payment options'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPaymentInfo(String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$method Selected'),
        content: Text(
          'You will be redirected to $method to complete your payment of ₹${widget.amount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceAssistant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceState>(
      builder: (context, voiceState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              'Restaurant',
                              widget.restaurantName,
                            ),
                            _buildSummaryRow(
                              'Subtotal',
                              '₹${widget.amount.toStringAsFixed(2)}',
                            ),
                            _buildSummaryRow(
                              'Delivery Fee',
                              widget.amount > 500 ? 'FREE' : '₹40',
                            ),
                            const Divider(height: 20),
                            _buildSummaryRow(
                              'Total Amount',
                              '₹${_getTotalAmount().toStringAsFixed(2)}',
                              isBold: true,
                              textColor: const Color(0xFFFF6B6B),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Payment Methods Section
                    const Text(
                      'Choose Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Expanded(
                      child: ListView(
                        children: [
                          _buildPaymentMethodCard(
                            'UPI / QR Payment',
                            'Scan QR code to pay',
                            Icons.qr_code_2,
                            Colors.purple,
                            () => _processPayment(),
                          ),
                          _buildPaymentMethodCard(
                            'Google Pay',
                            'Fast and secure UPI payment',
                            Icons.account_balance_wallet,
                            Colors.blue,
                            () => _showPaymentInfo('Google Pay'),
                          ),
                          _buildPaymentMethodCard(
                            'Credit/Debit Card',
                            'Pay with your card',
                            Icons.credit_card,
                            Colors.green,
                            () => _showPaymentInfo('Card'),
                          ),
                          _buildPaymentMethodCard(
                            'Cash on Delivery',
                            'Pay when food arrives',
                            Icons.money,
                            Colors.orange,
                            () => _showPaymentInfo('Cash on Delivery'),
                          ),
                        ],
                      ),
                    ),

                    // Pay Button
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pay ₹${_getTotalAmount().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🆕 VOICE LISTENING OVERLAY
              if (voiceState.isListening)
                VoiceListeningOverlay(
                  onClose: () {
                    final voiceState = Provider.of<VoiceState>(
                      context,
                      listen: false,
                    );
                    voiceState.setListeningState(false);
                  },
                  screenContext: 'payment',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textColor ?? Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: _isProcessing ? null : onTap,
      ),
    );
  }
}
