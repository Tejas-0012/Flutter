// lib/src/voice/wake_word_detector.dart
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class WakeWordDetector {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final StreamController<String> _wakeWordController =
      StreamController<String>.broadcast();
  bool _isListening = false;
  Timer? _inactivityTimer;

  Stream<String> get wakeWordStream => _wakeWordController.stream;

  Future<void> startListening() async {
    if (_isListening) return;

    bool initialized = await _speech.initialize(
      onStatus: _onWakeWordStatus,
      onError: _onWakeWordError,
    );

    if (initialized) {
      _isListening = true;
      _startWakeWordRecognition();
      print('🔊 Wake word detection started');
    } else {
      print('❌ Failed to initialize wake word detection');
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
      _inactivityTimer?.cancel();
      print('🔇 Wake word detection stopped');
    }
  }

  void _startWakeWordRecognition() {
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords.toLowerCase().trim();
          print('🎯 Wake word detected: "$text"');

          if (_containsWakeWord(text)) {
            _wakeWordController.add(text);
            _resetInactivityTimer();
          }
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
      onSoundLevelChange: (level) {},
    );

    _resetInactivityTimer();
  }

  bool _containsWakeWord(String text) {
    const wakeWords = ['hello', 'hey', 'hi platter', 'okay platter'];
    return wakeWords.any((word) => text.contains(word));
  }

  void _onWakeWordStatus(String status) {
    print('🔊 Wake word status: $status');

    if (status == 'done' && _isListening) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isListening) {
          _startWakeWordRecognition();
        }
      });
    }
  }

  void _onWakeWordError(Object error) {
    print('❌ Wake word error: $error');

    if (_isListening) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_isListening) {
          _startWakeWordRecognition();
        }
      });
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 10), () {
      print('⏰ Wake word detector inactive for 10 minutes, restarting...');
      if (_isListening) {
        _speech.stop();
        _startWakeWordRecognition();
      }
    });
  }

  void dispose() {
    stopListening();
    _inactivityTimer?.cancel();
    _wakeWordController.close();
  }
}
