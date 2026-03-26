import 'package:flutter/material.dart';
import '../../screens/game_screen.dart';
import '../../screens/games/food_trivia_game.dart';
import '../../screens/games/spin_wheel_game.dart';
import '../../screens/games/food_match_game.dart';
import '../../screens/games/guess_dish_game.dart';
import '../../screens/games/food_quiz_game.dart';

class GameStack extends StatelessWidget {
  const GameStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            switch (settings.name) {
              case '/':
              case '/gameHome':
                return const GameScreen();
              case '/foodTrivia':
                return const FoodTriviaGame();
              case '/spinWheel':
                return const SpinWheelGame();
              case '/foodMatch':
                return const FoodMatchGame();
              case '/guessDish':
                return const GuessDishGame();
              case '/foodQuiz':
                return const FoodQuizGame();
              default:
                return const GameScreen();
            }
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
      },
    );
  }
}
