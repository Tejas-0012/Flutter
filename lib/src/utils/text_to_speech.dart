// lib/src/utils/text_to_speech.dart
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _isInitialized = true;
  }

  static Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static Future<void> speakCartContents(int itemCount, double total) async {
    if (itemCount == 0) {
      await speak("Your cart is empty");
    } else {
      await speak(
        "You have $itemCount items in your cart. Total is ${total.toStringAsFixed(2)} rupees",
      );
    }
  }
}
