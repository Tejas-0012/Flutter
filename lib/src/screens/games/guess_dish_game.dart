import 'package:flutter/material.dart';

class Dish {
  final String name;
  final List<String> ingredients;
  final List<String> hints;
  final String image;

  const Dish({
    required this.name,
    required this.ingredients,
    required this.hints,
    required this.image,
  });
}

class GuessDishGame extends StatefulWidget {
  const GuessDishGame({super.key});

  @override
  State<GuessDishGame> createState() => _GuessDishGameState();
}

class _GuessDishGameState extends State<GuessDishGame> {
  int currentDish = 0;
  int score = 0;
  String userGuess = '';
  bool gameCompleted = false;
  int hintsUsed = 0;

  final List<Dish> dishes = const [
    Dish(
      name: 'pizza',
      ingredients: ['dough', 'cheese', 'sauce', 'toppings'],
      hints: ['Italian', 'Slices', 'Party'],
      image: '🍕',
    ),
    Dish(
      name: 'sushi',
      ingredients: ['rice', 'seaweed', 'fish', 'veg'],
      hints: ['Japanese', 'Soy sauce', 'Raw'],
      image: '🍣',
    ),
    Dish(
      name: 'burger',
      ingredients: ['bun', 'patty', 'lettuce', 'cheese'],
      hints: ['Fast food', 'Fries', 'American'],
      image: '🍔',
    ),
    Dish(
      name: 'tacos',
      ingredients: ['tortilla', 'meat', 'salsa', 'cheese'],
      hints: ['Mexican', 'Lime', 'Shell'],
      image: '🌮',
    ),
    Dish(
      name: 'pasta',
      ingredients: ['noodles', 'sauce', 'herbs', 'cheese'],
      hints: ['Italian', 'Shapes', 'Bread'],
      image: '🍝',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  void _handleGuess() {
    if (userGuess.trim().toLowerCase() ==
        dishes[currentDish].name.toLowerCase()) {
      setState(() {
        score++;
      });
    }

    setState(() {
      userGuess = '';
      hintsUsed = 0;
    });

    if (currentDish + 1 < dishes.length) {
      setState(() {
        currentDish++;
      });
    } else {
      setState(() {
        gameCompleted = true;
      });
      _showCompletionDialog();
    }
  }

  void _useHint() {
    if (hintsUsed < dishes[currentDish].hints.length) {
      setState(() {
        hintsUsed++;
      });
    }
  }

  void _showCompletionDialog() {
    final discount = ((score / dishes.length) * 15).floor() + 5;
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Game Completed!'),
            content: Text(
              'Score: $score/${dishes.length}\nWon $discount% OFF!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  void _restartGame() {
    setState(() {
      currentDish = 0;
      score = 0;
      userGuess = '';
      gameCompleted = false;
      hintsUsed = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (gameCompleted) {
      final discount = ((score / dishes.length) * 15).floor() + 5;
      return _buildScoreScreen(discount);
    }

    return _buildGameScreen();
  }

  Widget _buildScoreScreen(int discount) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Done! 🍽️',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score/${dishes.length}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF636E72)),
            ),
            const SizedBox(height: 6),
            Text(
              '$discount% OFF',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE17055),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE17055),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: Color(0xFFE17055)),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  color: Color(0xFFE17055),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final currentDishData = dishes[currentDish];
    final progressPercentage = ((currentDish + 1) / dishes.length) * 100;

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
                  icon: const Icon(Icons.arrow_back, size: 16),
                  color: const Color(0xFFE17055),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Text(
                  'Guess Dish',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Text(
                  'Score:$score',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE17055),
                  ),
                ),
              ],
            ),
          ),

          // Progress Container
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 6),
            child: Column(
              children: [
                Text(
                  '${currentDish + 1}/${dishes.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF636E72),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFE6E9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE17055),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dish Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Dish Emoji
                  Text(
                    currentDishData.image,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),

                  // Ingredients Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ingredients:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Ingredients Tags
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: currentDishData.ingredients.map((ingredient) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE17055),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ingredient,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Input Field
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        userGuess = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Dish name...',
                      hintStyle: TextStyle(color: Color(0xFF999999)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFDFE6E9)),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFDFE6E9)),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      filled: true,
                      fillColor: Color(0xFFF8F9FA),
                      contentPadding: EdgeInsets.all(8),
                    ),
                    style: const TextStyle(fontSize: 12),
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 8),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: userGuess.trim().isNotEmpty
                          ? _handleGuess
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userGuess.trim().isNotEmpty
                            ? const Color(0xFFE17055)
                            : const Color(0xFFBDC3C7),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Hints Section
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: hintsUsed < currentDishData.hints.length
                                ? _useHint
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  hintsUsed < currentDishData.hints.length
                                  ? const Color(0xFF4ECDC4)
                                  : const Color(0xFFBDC3C7),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              hintsUsed >= currentDishData.hints.length
                                  ? 'No Hints'
                                  : 'Hint',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Hint Display
                        if (hintsUsed > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(6),
                              border: const Border(
                                left: BorderSide(
                                  color: Color(0xFF4ECDC4),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              currentDishData.hints[hintsUsed - 1],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF636E72),
                                height: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
