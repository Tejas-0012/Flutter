import 'package:flutter/material.dart';

class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  const Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class Lifelines {
  int fiftyFifty;
  int skip;

  Lifelines({required this.fiftyFifty, required this.skip});
}

class FoodQuizGame extends StatefulWidget {
  const FoodQuizGame({super.key});

  @override
  State<FoodQuizGame> createState() => _FoodQuizGameState();
}

class _FoodQuizGameState extends State<FoodQuizGame>
    with SingleTickerProviderStateMixin {
  int currentQuestion = 0;
  int score = 0;
  int? selectedAnswer;
  bool showExplanation = false;
  bool gameCompleted = false;
  late Lifelines lifelines;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final List<Question> quizQuestions = const [
    Question(
      question: "Origin of Croissants?",
      options: ["France", "Austria", "Italy", "Germany"],
      correctAnswer: 1,
      explanation: "From Austria, inspired by kipferl.",
    ),
    Question(
      question: "Main ingredient in guacamole?",
      options: ["Peas", "Avocado", "Tomatoes", "Cucumber"],
      correctAnswer: 1,
      explanation: "Made from avocados.",
    ),
    Question(
      question: "NOT a type of pasta?",
      options: ["Farfalle", "Rigatoni", "Bruschetta", "Penne"],
      correctAnswer: 2,
      explanation: "Bruschetta is bread appetizer.",
    ),
    Question(
      question: "Saffron comes from?",
      options: ["Petals", "Stems", "Stigma", "Leaves"],
      correctAnswer: 2,
      explanation: "From saffron crocus stigma.",
    ),
    Question(
      question: "Vitamin in Citrus fruits?",
      options: ["Vit A", "Vit B", "Vit C", "Vit D"],
      correctAnswer: 2,
      explanation: "High in Vitamin C.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    lifelines = Lifelines(fiftyFifty: 1, skip: 2);
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: (currentQuestion + 1) / quizQuestions.length,
    ).animate(_progressController);
  }

  @override
  void didUpdateWidget(covariant FoodQuizGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateProgress();
  }

  void _updateProgress() {
    _progressController.animateTo(
      (currentQuestion + 1) / quizQuestions.length,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _handleAnswer(int answerIndex) {
    setState(() {
      selectedAnswer = answerIndex;
      showExplanation = true;
    });

    if (answerIndex == quizQuestions[currentQuestion].correctAnswer) {
      setState(() {
        score++;
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    final nextQuestionIndex = currentQuestion + 1;
    if (nextQuestionIndex < quizQuestions.length) {
      setState(() {
        currentQuestion = nextQuestionIndex;
        selectedAnswer = null;
        showExplanation = false;
      });
      _updateProgress();
    } else {
      setState(() {
        gameCompleted = true;
      });
    }
  }

  void _useFiftyFifty() {
    if (lifelines.fiftyFifty > 0) {
      setState(() {
        lifelines.fiftyFifty--;
      });
      _showAlert('50:50 Used!');
    }
  }

  void _useSkip() {
    if (lifelines.skip > 0) {
      setState(() {
        lifelines.skip--;
      });
      _nextQuestion();
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
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

  void _restartGame() {
    setState(() {
      currentQuestion = 0;
      score = 0;
      selectedAnswer = null;
      showExplanation = false;
      gameCompleted = false;
      lifelines = Lifelines(fiftyFifty: 1, skip: 2);
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
    if (gameCompleted) {
      final discount = (score / quizQuestions.length * 25).floor();
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
              'Complete! 🎓',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score/${quizQuestions.length}',
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
            const SizedBox(height: 12),
            Column(
              children: [
                Text(
                  '50:50: ${1 - lifelines.fiftyFifty}/1',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF636E72),
                  ),
                ),
                Text(
                  'Skips: ${2 - lifelines.skip}/2',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
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
    final currentQ = quizQuestions[currentQuestion];

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
                  'Quiz',
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
                  'Q${currentQuestion + 1}/${quizQuestions.length}',
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
                            color: const Color(0xFFE17055),
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

          // Lifelines Container
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: lifelines.fiftyFifty > 0 ? _useFiftyFifty : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lifelines.fiftyFifty > 0
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFFBDC3C7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '50:50 (${lifelines.fiftyFifty})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: lifelines.skip > 0 ? _useSkip : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lifelines.skip > 0
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFFBDC3C7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Skip (${lifelines.skip})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Question and Options
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text(
                    currentQ.question,
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
                      itemCount: currentQ.options.length,
                      itemBuilder: (context, index) {
                        final isCorrect = index == currentQ.correctAnswer;
                        final isSelected = selectedAnswer == index;
                        final isDisabled = selectedAnswer != null;

                        Color backgroundColor = const Color(0xFFF8F9FA);
                        Color borderColor = const Color(0xFFDFE6E9);

                        if (isSelected && isCorrect) {
                          backgroundColor = const Color(0xFFD4EDDA);
                          borderColor = const Color(0xFFC3E6CB);
                        } else if (isSelected && !isCorrect) {
                          backgroundColor = const Color(0xFFF8D7DA);
                          borderColor = const Color(0xFFF5C6CB);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ElevatedButton(
                            onPressed: isDisabled
                                ? null
                                : () => _handleAnswer(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: backgroundColor,
                              foregroundColor: const Color(0xFF2D3436),
                              elevation: 0,
                              padding: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(color: borderColor, width: 1),
                              ),
                            ),
                            child: Text(
                              currentQ.options[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF2D3436),
                                fontWeight:
                                    (isSelected || (isDisabled && isCorrect))
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Explanation
                  if (showExplanation)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4F8),
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF4ECDC4), width: 3),
                        ),
                      ),
                      child: Text(
                        currentQ.explanation,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF636E72),
                          height: 1.4,
                        ),
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
