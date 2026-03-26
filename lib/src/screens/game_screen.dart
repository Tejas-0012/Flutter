import 'package:flutter/material.dart';

class Game {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final String screen;

  const Game({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  final List<Game> games = const [
    Game(
      id: '1',
      title: 'Food Trivia',
      description: 'Test knowledge',
      icon: '🍕',
      color: Color(0xFFFF6B6B),
      screen: '/foodTrivia',
    ),
    Game(
      id: '2',
      title: 'Spin & Save',
      description: 'Win discounts',
      icon: '🎯',
      color: Color(0xFF4ECDC4),
      screen: '/spinWheel',
    ),
    Game(
      id: '3',
      title: 'Food Match',
      description: 'Match pairs',
      icon: '🧩',
      color: Color(0xFF45B7D1),
      screen: '/foodMatch',
    ),
    Game(
      id: '4',
      title: 'Guess Dish',
      description: 'From ingredients',
      icon: '🔍',
      color: Color(0xFF96CEB4),
      screen: '/guessDish',
    ),
    Game(
      id: '5',
      title: 'Food Quiz',
      description: 'Daily challenges',
      icon: '📝',
      color: Color(0xFFFFEAA7),
      screen: '/foodQuiz',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: const Column(
              children: [
                Text(
                  'Platter Games',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Play & Win!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF636E72)),
                ),
              ],
            ),
          ),

          // Rewards Section
          Container(
            margin: const EdgeInsets.only(top: 6, left: 8, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Rewards',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRewardItem('5%', 'OFF'),
                    _buildRewardItem('₹50', 'CASH'),
                    _buildRewardItem('FREE', 'DELIVERY'),
                  ],
                ),
              ],
            ),
          ),

          // Games Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return _buildGameCard(games[index], context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE17055),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: Color(0xFF636E72)),
        ),
      ],
    );
  }

  Widget _buildGameCard(Game game, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          color: game.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to the game screen
              Navigator.pushNamed(context, game.screen);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(game.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    game.description,
                    style: const TextStyle(fontSize: 8, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
