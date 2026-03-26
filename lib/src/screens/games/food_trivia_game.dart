import 'package:flutter/material.dart';

class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;

  const Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class FoodTriviaGame extends StatefulWidget {
  const FoodTriviaGame({super.key});

  @override
  State<FoodTriviaGame> createState() => _FoodTriviaGameState();
}

class _FoodTriviaGameState extends State<FoodTriviaGame>
    with SingleTickerProviderStateMixin {
  int currentQuestion = 0;
  int score = 0;
  bool showScore = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final List<Question> triviaQuestions = const [
    Question(
      question: "Which country is 'Land of Rising Sun'?",
      options: ["China", "Japan", "Thailand", "India"],
      correctAnswer: 1,
    ),
    Question(
      question: "Main ingredient in hummus?",
      options: ["Lentils", "Chickpeas", "Beans", "Peas"],
      correctAnswer: 1,
    ),
    Question(
      question: "Spice called 'red gold'?",
      options: ["Cinnamon", "Saffron", "Turmeric", "Paprika"],
      correctAnswer: 1,
    ),
    Question(
      question: "Cheese in Pizza Margherita?",
      options: ["Cheddar", "Parmesan", "Mozzarella", "Gouda"],
      correctAnswer: 2,
    ),
    Question(
      question: "NOT a type of pasta?",
      options: ["Fettuccine", "Rigatoni", "Bruschetta", "Penne"],
      correctAnswer: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: (currentQuestion + 1) / triviaQuestions.length,
    ).animate(_progressController);
  }

  @override
  void didUpdateWidget(covariant FoodTriviaGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateProgress();
  }

  void _updateProgress() {
    _progressController.animateTo(
      (currentQuestion + 1) / triviaQuestions.length,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _handleAnswer(int selectedAnswer) {
    if (selectedAnswer == triviaQuestions[currentQuestion].correctAnswer) {
      setState(() {
        score++;
      });
    }

    final nextQuestion = currentQuestion + 1;
    if (nextQuestion < triviaQuestions.length) {
      setState(() {
        currentQuestion = nextQuestion;
      });
      _updateProgress();
    } else {
      setState(() {
        showScore = true;
      });
    }
  }

  void _restartGame() {
    setState(() {
      currentQuestion = 0;
      score = 0;
      showScore = false;
    });
    _progressController.reset();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (showScore) {
      final discount = (score / triviaQuestions.length * 20).floor();
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
              'Complete! 🎉',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score/${triviaQuestions.length}',
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
                  horizontal: 24,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Play Again',
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
                  horizontal: 24,
                  vertical: 8,
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
                  'Trivia',
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
                  'Q${currentQuestion + 1}/${triviaQuestions.length}',
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
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF04FA00),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Question and Options
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    triviaQuestions[currentQuestion].question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          triviaQuestions[currentQuestion].options.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ElevatedButton(
                            onPressed: () => _handleAnswer(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2D3436),
                              elevation: 0,
                              padding: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              triviaQuestions[currentQuestion].options[index],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                          ),
                        );
                      },
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
