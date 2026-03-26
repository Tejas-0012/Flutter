import 'package:flutter/material.dart';
import '../screens/game_screen.dart';
import '../screens/games/food_match_game.dart';
import '../screens/games/food_quiz_game.dart';
import '../screens/games/food_trivia_game.dart';
import '../screens/games/guess_dish_game.dart';
import '../screens/games/spin_wheel_game.dart';

class GameRoutes {
  static const gameScreen = '/games';
  static const foodTrivia = '/foodTrivia';
  static const spinWheel = '/spinWheel';
  static const foodMatch = '/foodMatch';
  static const guessDish = '/guessDish';
  static const foodQuiz = '/foodQuiz';

  static Map<String, WidgetBuilder> routes = {
    gameScreen: (context) => const GameScreen(),
    foodTrivia: (context) => const FoodTriviaGame(),
    spinWheel: (context) => const SpinWheelGame(),
    foodMatch: (context) => const FoodMatchGame(),
    guessDish: (context) => const GuessDishGame(),
    foodQuiz: (context) => const FoodQuizGame(),
  };
}
