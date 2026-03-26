import 'package:flutter/material.dart';

class CardItem {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardItem({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class FoodMatchGame extends StatefulWidget {
  const FoodMatchGame({super.key});

  @override
  State<FoodMatchGame> createState() => _FoodMatchGameState();
}

class _FoodMatchGameState extends State<FoodMatchGame> {
  List<CardItem> cards = [];
  List<int> flippedCards = [];
  List<int> matchedCards = [];
  int moves = 0;
  bool gameCompleted = false;

  final List<String> foodItems = [
    '🍕',
    '🍔',
    '🍟',
    '🌭',
    '🍿',
    '🧁',
    '🍫',
    '🍩',
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    List<CardItem> gameCards = [];

    // Create pairs of cards
    for (String emoji in foodItems) {
      gameCards.add(CardItem(id: gameCards.length, emoji: emoji));
      gameCards.add(CardItem(id: gameCards.length, emoji: emoji));
    }

    // Shuffle cards
    gameCards.shuffle();

    setState(() {
      cards = gameCards;
      flippedCards = [];
      matchedCards = [];
      moves = 0;
      gameCompleted = false;
    });
  }

  void _handleCardPress(int cardId) {
    if (flippedCards.length >= 2 ||
        flippedCards.contains(cardId) ||
        matchedCards.contains(cardId) ||
        gameCompleted) {
      return;
    }

    List<int> newFlippedCards = [...flippedCards, cardId];
    setState(() {
      flippedCards = newFlippedCards;
      cards = cards
          .map(
            (card) => card.id == cardId ? card.copyWith(isFlipped: true) : card,
          )
          .toList();
    });

    if (newFlippedCards.length == 2) {
      setState(() {
        moves++;
      });
      _checkForMatch(newFlippedCards);
    }
  }

  void _checkForMatch(List<int> flippedCardIds) {
    final firstCardId = flippedCardIds[0];
    final secondCardId = flippedCardIds[1];

    final firstCard = cards.firstWhere((card) => card.id == firstCardId);
    final secondCard = cards.firstWhere((card) => card.id == secondCardId);

    if (firstCard.emoji == secondCard.emoji) {
      List<int> newMatchedCards = [...matchedCards, firstCardId, secondCardId];
      setState(() {
        matchedCards = newMatchedCards;
        flippedCards = [];
        cards = cards
            .map(
              (card) => newMatchedCards.contains(card.id)
                  ? card.copyWith(isMatched: true)
                  : card,
            )
            .toList();
      });

      if (newMatchedCards.length == cards.length) {
        setState(() {
          gameCompleted = true;
        });
        final discount = (5 > 20 - (moves / 2).floor())
            ? 5
            : 20 - (moves / 2).floor();
        Future.delayed(const Duration(milliseconds: 500), () {
          _showCompletionDialog(discount);
        });
      }
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          flippedCards = [];
          cards = cards
              .map(
                (card) => flippedCardIds.contains(card.id)
                    ? card.copyWith(isFlipped: false)
                    : card,
              )
              .toList();
        });
      });
    }
  }

  void _showCompletionDialog(int discount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Completed!'),
          content: Text('Completed in $moves moves!\nWon $discount% OFF!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(CardItem card) {
    return GestureDetector(
      onTap: () => _handleCardPress(card.id),
      child: Container(
        width: (MediaQuery.of(context).size.width - 80) / 4,
        height: (MediaQuery.of(context).size.width - 180) / 4,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: card.isFlipped || card.isMatched
              ? Colors.white
              : const Color(0xFFE17055),
          borderRadius: BorderRadius.circular(6),
          border: (card.isFlipped || card.isMatched)
              ? Border.all(color: const Color(0xFFE17055), width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            card.isFlipped || card.isMatched ? card.emoji : '?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxDiscount = (5 > 20 - (moves / 2).floor())
        ? 5
        : 20 - (moves / 2).floor();

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
                  'Match',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Text(
                  'Moves:$moves',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE17055),
                  ),
                ),
              ],
            ),
          ),

          // Game Info
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${matchedCards.length ~/ 2}/${foodItems.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF636E72),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Game Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(cards[index]);
                },
              ),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _initializeGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE17055),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Restart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Max: ${maxDiscount.toInt()}% OFF',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF636E72),
                    fontWeight: FontWeight.bold,
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

// Extension to easily copy CardItem with modified properties
extension CardItemCopyWith on CardItem {
  CardItem copyWith({bool? isFlipped, bool? isMatched}) {
    return CardItem(
      id: id,
      emoji: emoji,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}
