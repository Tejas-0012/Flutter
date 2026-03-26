import 'package:flutter/material.dart';
import 'dart:math';

class SpinWheelGame extends StatefulWidget {
  const SpinWheelGame({super.key});

  @override
  State<SpinWheelGame> createState() => _SpinWheelGameState();
}

class _SpinWheelGameState extends State<SpinWheelGame>
    with SingleTickerProviderStateMixin {
  bool spinning = false;
  String? result;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  int spins = 3;

  final List<String> rewards = [
    '5% OFF',
    '₹50 CASH',
    'FREE DEL',
    '10% OFF',
    'TRY AGAIN',
    '₹25 CASH',
    '15% OFF',
    'BUY 1 GET 1',
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    );
  }

  void _spinWheel() {
    if (spinning || spins <= 0) return;

    setState(() {
      spinning = true;
      result = null;
    });

    final randomSpin =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 1000)) + 3600;

    _spinController.forward(from: 0).then((_) {
      final actualRotation = (randomSpin % 360);
      final segmentAngle = 360 / rewards.length;
      final winningIndex =
          ((360 - actualRotation) ~/ segmentAngle) % rewards.length;

      setState(() {
        result = rewards[winningIndex];
        spinning = false;
        spins--;
      });

      if (rewards[winningIndex] != 'TRY AGAIN') {
        Future.delayed(const Duration(milliseconds: 100), () {
          _showResultDialog(rewards[winningIndex]);
        });
      }
    });
  }

  void _showResultDialog(String reward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You won: $reward'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelSize = screenWidth - 140;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(6),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Text(
                    '←Back',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE17055)),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Text(
                  'Spin Wheel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Text(
                  'Remaining:$spins',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE17055),
                  ),
                ),
              ],
            ),
          ),

          // Wheel Container
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wheel
                    Container(
                      width: wheelSize,
                      height: wheelSize,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2D3436),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(wheelSize / 2),
                      ),
                      child: AnimatedBuilder(
                        animation: _spinAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle:
                                _spinAnimation.value *
                                6 *
                                3.14159, // 1080 degrees in radians
                            child: CustomPaint(
                              painter: WheelPainter(rewards: rewards),
                            ),
                          );
                        },
                      ),
                    ),

                    // Pointer
                    Positioned(
                      top: -12,
                      child: Container(
                        width: 0,
                        height: 0,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: CustomPaint(painter: PointerPainter()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Spin Button
                ElevatedButton(
                  onPressed: (spinning || spins <= 0) ? null : _spinWheel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (spinning || spins <= 0)
                        ? const Color(0xFFBDC3C7)
                        : const Color(0xFFE17055),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    spinning
                        ? 'Spinning...'
                        : spins <= 0
                        ? 'No Spins'
                        : 'SPIN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Result Display
                if (result != null)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Won: $result',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ),

                // Info Container
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• Spin to win discounts',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF636E72),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• 3 spins left today',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF636E72),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Auto-applies to orders',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> rewards;

  WheelPainter({required this.rewards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * 3.14159 / rewards.length;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < rewards.length; i++) {
      final startAngle = i * segmentAngle;
      final endAngle = (i + 1) * segmentAngle;

      // Draw segment
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false,
        )
        ..close();

      final paint = Paint()
        ..color = i % 2 == 0 ? const Color(0xFFE17055) : const Color(0xFFFDCB6E)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // Draw text
      final textAngle = startAngle + segmentAngle / 2;
      final textX = center.dx + (radius * 0.6) * cos(textAngle);
      final textY = center.dy + (radius * 0.6) * sin(textAngle);

      textPainter.text = TextSpan(
        text: rewards[i],
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + 3.14159 / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.1, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE17055)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(-10, 20)
      ..lineTo(10, 20)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
