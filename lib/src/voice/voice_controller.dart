// lib/src/voice/voice_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'wake_word_detector.dart';
import 'voice_commands.dart';
import 'text_to_speech.dart';

class VoiceController with ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final WakeWordDetector _wakeWordDetector = WakeWordDetector();
  final VoiceCommands _voiceCommands = VoiceCommands();
  bool _showOverlay = false;

  // Voice state tracking
  bool _isListening = false;
  bool _isWakeWordActive = false;
  bool _shouldBeListening = true; // MASTER CONTROL - ALWAYS TRUE FOR CONTINUOUS
  String _lastSpokenText = '';
  String _statusMessage = 'Voice system starting...';
  StreamSubscription<String>? _wakeWordSubscription;
  Timer? _restartTimer;

  bool get isListening => _isListening;
  bool get isWakeWordActive => _isWakeWordActive;
  String get lastSpokenText => _lastSpokenText;
  String get statusMessage => _statusMessage;
  bool get showOverlay => _showOverlay;

  VoiceController() {
    print('🎯 VoiceController created - Continuous mode');
    _initializeSpeech();
    _initializeWakeWord();
    TextToSpeech.initialize();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    if (available) {
      _updateStatus('Voice ready - Always listening');
      _startContinuousListening(); // START IMMEDIATELY
    } else {
      _updateStatus('Speech recognition not available');
    }
  }

  void _initializeWakeWord() {
    _wakeWordSubscription = _wakeWordDetector.wakeWordStream.listen((text) {
      if (text.toLowerCase().contains('hello')) {
        _activateVoiceMode();
      }
    });
  }

  void _onSpeechStatus(String status) {
    print('Speech status: $status');

    // Handle all speech states for continuous operation
    switch (status) {
      case 'listening':
        _isListening = true;
        _updateStatus('Listening for commands...');
        break;
      case 'notListening':
        _isListening = false;
        _handleSessionEnd();
        break;
      case 'done':
        _isListening = false;
        _handleSessionEnd();
        break;
      case 'doneNoResult':
        _isListening = false;
        _handleSessionEnd();
        break;
    }

    notifyListeners();
  }

  void _handleSessionEnd() {
    print('🔄 Speech session ended, restarting...');
    // Restart listening after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_shouldBeListening && !_isListening) {
        _startContinuousListening();
      }
    });
  }

  void _onSpeechError(Object error) {
    print('Speech error: $error');
    _isListening = false;

    // Auto-restart on error after longer delay
    if (_shouldBeListening) {
      _updateStatus('Error - Restarting in 3 seconds...');
      Future.delayed(const Duration(seconds: 3), () {
        if (_shouldBeListening && !_isListening) {
          _startContinuousListening();
        }
      });
    }
  }

  void _startContinuousListening() {
    if (!_isListening && _shouldBeListening) {
      print('🎤 Starting continuous listening session...');
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastSpokenText = result.recognizedWords;
            print('🎯 Speech detected: "$_lastSpokenText"');
            _processVoiceCommand(_lastSpokenText);
          }
        },
        listenFor: const Duration(minutes: 10), // VERY LONG SESSIONS
        pauseFor: const Duration(seconds: 15), // LONG PAUSES
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation, // BEST FOR CONTINUOUS
        onSoundLevelChange: (level) {
          // Can use for visual feedback if needed
        },
      );
      _isListening = true;
      _updateStatus('Always listening... Say "hello"');
      notifyListeners();
    }
  }

  void _activateVoiceMode() {
    if (!_isWakeWordActive) {
      _isWakeWordActive = true;
      _showOverlay = true;
      _updateStatus('Voice mode active! Say a command...');
      TextToSpeech.speak("Voice mode activated");
      notifyListeners();

      // Auto-hide overlay after 30 seconds of inactivity
      Future.delayed(const Duration(seconds: 30), () {
        if (_isWakeWordActive && _showOverlay) {
          _deactivateVoiceMode();
        }
      });
    }
  }

  void _deactivateVoiceMode() {
    _showOverlay = false;
    _isWakeWordActive = false;
    _updateStatus('Voice active (background)... Say "hello" to show overlay');
    notifyListeners();
    // CRITICAL: Don't stop listening - voice continues in background
  }

  void stopVoiceCompletely() {
    _isWakeWordActive = false;
    _showOverlay = false;
    _shouldBeListening = false; // STOP ALL LISTENING
    _speech.stop();
    _updateStatus('Voice system stopped');
    TextToSpeech.speak("Voice mode deactivated");
    notifyListeners();
  }

  void _processVoiceCommand(String command) {
    _updateStatus('Processing: "$command"');

    // Handle stop/close commands
    if (command.contains('stop') || command.contains('close')) {
      _deactivateVoiceMode();
      TextToSpeech.speak("Voice mode hidden");
      return;
    }

    final handled = _voiceCommands.executeCommand(command);

    if (handled) {
      _updateStatus('Command executed: "$command"');
      TextToSpeech.speakCommandFeedback(command, true);

      // Auto-hide overlay after successful command
      Future.delayed(const Duration(seconds: 2), () {
        _deactivateVoiceMode();
      });
    } else {
      _updateStatus('Unknown command: "$command". Try again.');
      TextToSpeech.speakCommandFeedback(command, false);
    }

    notifyListeners();
  }

  void _updateStatus(String message) {
    _statusMessage = message;
    print('Voice Status: $message');
  }

  // Manual activation/deactivation methods
  void activateManually() {
    _activateVoiceMode();
  }

  void deactivateManually() {
    _deactivateVoiceMode();
  }

  // Wake word detection control
  void startWakeWordDetection() {
    _shouldBeListening = true;
    _wakeWordDetector.startListening();
    _startContinuousListening();
    print('🎯 Voice system started - Continuous listening enabled');
  }

  void stopWakeWordDetection() {
    _shouldBeListening = false;
    _wakeWordDetector.stopListening();
    _speech.stop();
    print('🔇 Voice system stopped');
  }

  // Set current screen for context-aware commands
  void setCurrentScreen(String screen) {
    _voiceCommands.setCurrentScreen(screen);
  }

  @override
  void dispose() {
    _shouldBeListening = false;
    _wakeWordSubscription?.cancel();
    _wakeWordDetector.dispose();
    _speech.stop();
    TextToSpeech.stop();
    _restartTimer?.cancel();
    print('🔇 VoiceController disposed');
    super.dispose();
  }
}

// Voice Overlay Widget
class VoiceOverlay extends StatelessWidget {
  final VoiceController voiceController;

  const VoiceOverlay({super.key, required this.voiceController});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ValueNotifier<bool>(voiceController.showOverlay),
      builder: (context, showOverlay, child) {
        if (!showOverlay) return const SizedBox.shrink();

        return Stack(
          children: [
            // Semi-transparent background
            GestureDetector(
              onTap: () => voiceController.deactivateManually(),
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Voice interface
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvatarGlow(
                    glowColor: Colors.orange,
                    endRadius: 80.0,
                    duration: const Duration(milliseconds: 2000),
                    repeat: true,
                    showTwoGlows: true,
                    repeatPauseDuration: const Duration(milliseconds: 100),
                    child: Material(
                      elevation: 8.0,
                      shape: const CircleBorder(),
                      child: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        radius: 40,
                        child: Icon(
                          voiceController.isListening
                              ? Icons.mic
                              : Icons.mic_none,
                          color: Colors.orange,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    voiceController.statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (voiceController.lastSpokenText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '"${voiceController.lastSpokenText}"',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => voiceController.deactivateManually(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Hide Overlay'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
