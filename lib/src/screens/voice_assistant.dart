// lib/src/screens/voice_assistant.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceAssistant {
  static final VoiceAssistant _instance = VoiceAssistant._internal();
  factory VoiceAssistant() => _instance;
  VoiceAssistant._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _wakeWordDetected = false;
  String _partialText = '';
  Function(String)? _onCommandDetected;
  Function(bool)? _onListeningStateChanged;

  static const String WAKE_WORD = "hello";

  // Initialize voice assistant
  Future<void> init() async {
    try {
      await _setupTTS();

      // Initialize speech recognition with error handling
      bool hasPermission = await _initializeSpeech();

      if (hasPermission) {
        print("✅ Speech recognition ready");
        // Don't start listening immediately - wait for app to be fully loaded
        Future.delayed(Duration(seconds: 3), () {
          _startContinuousListening();
        });
      } else {
        print("❌ Speech recognition permission denied");
      }
    } catch (e) {
      print("❌ Voice assistant init error: $e");
    }
  }

  Future<bool> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print("🎤 Speech status: $status");
          // Only restart on specific statuses, not every status change
          if (status == 'done') {
            print("🔄 Session completed, restarting...");
            Future.delayed(Duration(seconds: 2), () {
              _startContinuousListening();
            });
          }
        },
        onError: (error) {
          _handleSpeechError(error);
        },
      );

      if (available) {
        print("✅ Speech recognition available");
        return true;
      } else {
        print("❌ Speech recognition not available");
        return false;
      }
    } catch (e) {
      print("❌ Speech initialization error: $e");
      return false;
    }
  }

  Future<void> _setupPermissions() async {
    await Permission.microphone.request();
    await Permission.speech.request();
  }

  Future<void> _setupTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  bool _isRestarting = false; // Add this class variable

  void _startContinuousListening() {
    if (_isRestarting) {
      print("⏸️ Already restarting, skipping...");
      return;
    }

    if (!_speech.isListening) {
      _isRestarting = true;
      print("🎤 Starting continuous listening...");

      _speech
          .listen(
            onResult: _onSpeechResult,
            listenFor: Duration(seconds: 20),
            pauseFor: Duration(seconds: 5), // Reasonable pause time
            partialResults: true,
            localeId: "en_US",
            listenMode: stt.ListenMode.dictation,
            onSoundLevelChange: (level) {
              if (level > 5.0) {
                // Only log significant levels
                print("🔊 Sound: ${level.toStringAsFixed(1)}");
              }
            },
            cancelOnError: true,
          )
          .then((value) {
            print("✅ Listening session started");
            _isRestarting = false;
          })
          .catchError((error) {
            print("❌ Listening failed: $error");
            _isRestarting = false;
            // Wait longer before retry
            Future.delayed(Duration(seconds: 5), () {
              _startContinuousListening();
            });
          });
    } else {
      print("🎤 Already listening, skipping restart");
      _isRestarting = false;
    }
  }

  void _onSpeechResult(result) {
    print("🎤 Speech result: ${result.recognizedWords}");

    if (result.finalResult) {
      _processFinalResult(result.recognizedWords);
    } else {
      _processPartialResult(result.recognizedWords);
    }
  }

  void _processPartialResult(String partial) {
    String cleanPartial = partial.toLowerCase().trim();

    if (cleanPartial.isNotEmpty) {
      // Replace the text instead of accumulating
      _partialText = cleanPartial;
    }

    print("🔍 Partial: '$_partialText'");

    // More precise wake word detection
    if (_partialText.contains("hello") && !_wakeWordDetected) {
      _wakeWordDetected = true;
      print("🎯 Wake word detected: '$_partialText'");
      _onWakeWordDetected();
    }
  }

  void _processFinalResult(String text) {
    if (!_wakeWordDetected) {
      // Check if wake word is in final result
      if (text.toLowerCase().contains("hello")) {
        _wakeWordDetected = true;
        print("🎯 Wake word detected in final result");
        _onWakeWordDetected();

        // Extract command after wake word
        String command = text.toLowerCase().replaceAll("hello", "").trim();
        print("➡️ Command after wake word: '$command'");
        if (command.isNotEmpty) {
          _processCommand(command);
        }
        return;
      }
    } else {
      // We already detected wake word, process the command
      String command = text.toLowerCase().trim();
      if (command.isNotEmpty) {
        _processCommand(command);
      }
    }

    _wakeWordDetected = false;
    _partialText = "";
  }

  void _processCommand(String command) {
    print("🎯 Processing command: '$command'");
    _onCommandDetected?.call(command);
    _tts.speak("Got it");
  }

  void _onWakeWordDetected() {
    _tts.speak("I'm listening");
    _onListeningStateChanged?.call(true);

    Future.delayed(Duration(seconds: 25), () {
      if (_wakeWordDetected) {
        _wakeWordDetected = false;
        _onListeningStateChanged?.call(false);
        _tts.speak("Listening ended");
      }
    });
  }

  void _handleSpeechError(error) {
    print("🎤 Speech error: $error");

    String errorStr = error.toString();

    if (errorStr.contains('error_no_match') ||
        errorStr.contains('error_speech_timeout')) {
      print("🔄 No speech detected, normal timeout - restarting...");
      Future.delayed(Duration(seconds: 3), () {
        _startContinuousListening();
      });
    } else if (errorStr.contains('error_client')) {
      print("🔄 Client error, waiting longer to restart...");
      Future.delayed(Duration(seconds: 10), () {
        _startContinuousListening();
      });
    } else {
      print("🔄 Unknown error, restarting in 5 seconds...");
      Future.delayed(Duration(seconds: 25), () {
        _startContinuousListening();
      });
    }
  }

  // Public methods
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  void setScreenContext(String screen) {
    // Context can be used for screen-specific commands
  }

  void setCallbacks({
    Function(String)? onCommandDetected,
    Function(bool)? onListeningStateChanged,
  }) {
    _onCommandDetected = onCommandDetected;
    _onListeningStateChanged = onListeningStateChanged;
  }

  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
