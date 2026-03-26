import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/context/voice_state.dart';

class VoiceListeningOverlay extends StatefulWidget {
  final VoidCallback? onClose;
  final String screenContext; // Add this to show context-specific commands

  const VoiceListeningOverlay({
    super.key,
    this.onClose,
    this.screenContext = 'general', // Default to general
  });

  @override
  State<VoiceListeningOverlay> createState() => _VoiceListeningOverlayState();
}

class _VoiceListeningOverlayState extends State<VoiceListeningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(Icons.mic, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Listening...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Say "Hello" followed by your command',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildCommandExamples(),
              ],
            ),
          ),

          // Close button at top-right
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: _handleClose,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandExamples() {
    List<String> commands = _getCommandsForContext();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Try saying:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: commands
                .map((command) => _CommandChip(text: command))
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getCommandsForContext() {
    switch (widget.screenContext) {
      case 'cart':
        return [
          'Hello remove [item]',
          'Hello checkout',
          'Hello clear cart',
          'Hello what\'s in my cart',
          'Hello increase [item]',
          'Hello decrease [item]',
          'Hello total amount',
          'Hello go back',
          'Hello go home',
        ];
      case 'menu':
        return [
          'Hello add [item] to cart',
          'Hello search [item]',
          'Hello filter by [category]',
          'Hello go to cart',
          'Hello go back',
        ];
      case 'home':
        return [
          'Hello show me [mood] food',
          'Hello search [restaurant]',
          'Hello go to cart',
          'Hello navigate to games',
        ];
      case 'payment':
        return [
          'Hello pay now',
          'Hello cancel payment',
          'Hello scan QR',
          'Hello Google Pay',
          'Hello card payment',
          'Hello cash delivery',
          'Hello go back',
          'Hello go home',
        ];
      case 'qr_scanner':
        return ['Hello make payment', 'Hello cancel payment', 'Hello go back'];
      default:
        return [
          'Hello go to cart',
          'Hello show me happy food',
          'Hello navigate to games',
          'Hello close voice',
        ];
    }
  }

  void _handleClose() {
    final voiceState = context.read<VoiceState>();
    voiceState.setListeningState(false);
    widget.onClose?.call();
  }
}

class _CommandChip extends StatelessWidget {
  final String text;

  const _CommandChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }
}
