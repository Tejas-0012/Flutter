import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/qr_scanner_manager.dart';
import '../context/voice_state.dart';
import '../utils/voice_command_processor.dart';
import '../screens/voice_assistant.dart';
import '../../widgets/voice_listening_overlay.dart';

class RealQRScannerScreen extends StatefulWidget {
  final String restaurantName;
  final double amount;

  const RealQRScannerScreen({
    super.key,
    required this.restaurantName,
    required this.amount,
  });

  @override
  State<RealQRScannerScreen> createState() => _RealQRScannerScreenState();
}

class _RealQRScannerScreenState extends State<RealQRScannerScreen> {
  bool _isScanning = true;
  bool _showPaymentOptions = false;
  final VoiceAssistant _voiceAssistant = VoiceAssistant();

  @override
  void initState() {
    super.initState();
    _startScanning();
    _setupVoiceAssistant();
  }

  void _setupVoiceAssistant() {
    _voiceAssistant.setScreenContext('qr_scanner');
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
    final processed = VoiceCommandProcessor.processCommand(
      command,
      'qr_scanner',
    );

    switch (processed['command']) {
      case 'make_payment':
        _handleVoiceMakePayment();
        voiceState.updateCommandResult('make_payment', 'Making payment');
        break;

      case 'cancel_payment':
        _handleVoiceCancelPayment();
        voiceState.updateCommandResult('cancel_payment', 'Cancelling payment');
        break;

      case 'back':
        _handleVoiceNavigateBack();
        voiceState.updateCommandResult('back', 'Going back');
        break;

      default:
        _voiceAssistant.speak(
          "Sorry, I didn't understand. Try: make payment or cancel payment",
        );
    }
  }

  void _handleVoiceMakePayment() {
    _voiceAssistant.speak("Confirming payment");
    _makePayment();
  }

  void _handleVoiceCancelPayment() {
    _voiceAssistant.speak("Cancelling payment");
    _cancelPayment();
  }

  void _handleVoiceNavigateBack() {
    _voiceAssistant.speak("Going back");
    Navigator.pop(context, null);
  }

  void _startScanning() async {
    if (kIsWeb) {
      // For web, use our fake scanner
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isScanning = false;
          _showPaymentOptions = true;
        });
        _voiceAssistant.speak(
          "QR code detected. Say make payment or cancel payment",
        );
      }
    } else {
      // For mobile, you can use actual QR scanner here
      final scanner = QrScannerManager();
      final success = await scanner.scanQRCode();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _showPaymentOptions = success;
        });
        if (success) {
          _voiceAssistant.speak(
            "QR code detected. Say make payment or cancel payment",
          );
        }
      }
    }
  }

  void _makePayment() {
    _voiceAssistant.speak("Payment successful");
    Navigator.pop(context, true);
  }

  void _cancelPayment() {
    _voiceAssistant.speak("Payment cancelled");
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _voiceAssistant.dispose();
    super.dispose();
  }

  Widget _buildWebScanner() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
        const SizedBox(height: 20),
        const Text(
          'Web QR Scanner Simulation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Amount: ₹${widget.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, color: Colors.green),
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 10),
        const Text('Simulating QR scan...'),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          'QR Code Detected!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          '₹${widget.amount.toStringAsFixed(2)} • ${widget.restaurantName}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: _makePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Make Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: _cancelPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Cancel Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceState>(
      builder: (context, voiceState, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Scan QR Code')),
          body: Stack(
            children: [
              Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Container(
                    width: 300,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: _showPaymentOptions
                        ? _buildPaymentOptions()
                        : _buildWebScanner(),
                  ),
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
                  screenContext: 'qr_scanner',
                ),
            ],
          ),
        );
      },
    );
  }
}
