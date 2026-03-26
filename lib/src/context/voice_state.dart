// lib/src/providers/voice_state.dart
import 'package:flutter/foundation.dart';

class VoiceState with ChangeNotifier {
  bool _isListening = false;
  bool _wakeWordDetected = false;
  String _lastCommand = "";
  String _lastResult = "";
  bool _voiceModeActive = true;
  String _currentScreen = 'home';
  bool _showOverlay = false;
  String _statusMessage = "Listening...";
  String _lastSpokenText = "";

  bool get isListening => _isListening;
  bool get wakeWordDetected => _wakeWordDetected;
  String get lastCommand => _lastCommand;
  String get lastResult => _lastResult;
  bool get voiceModeActive => _voiceModeActive;
  String get currentScreen => _currentScreen;
  bool get showOverlay => _showOverlay;
  String get statusMessage => _statusMessage;
  String get lastSpokenText => _lastSpokenText;

  void setListeningState(bool listening) {
    _isListening = listening;
    _showOverlay = listening;
    notifyListeners();
  }

  void setWakeWordDetected(bool detected) {
    _wakeWordDetected = detected;
    notifyListeners();
  }

  void updateCommandResult(String command, String result) {
    _lastCommand = command;
    _lastResult = result;
    notifyListeners();
  }

  void setCurrentScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void toggleVoiceMode() {
    _voiceModeActive = !_voiceModeActive;
    notifyListeners();
  }

  // NEW: Overlay control methods
  void showVoiceOverlay({String message = "Listening..."}) {
    _showOverlay = true;
    _statusMessage = message;
    notifyListeners();
  }

  void hideVoiceOverlay() {
    _showOverlay = false;
    _statusMessage = "Listening...";
    _lastSpokenText = "";
    notifyListeners();
  }

  void updateStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void updateLastSpokenText(String text) {
    _lastSpokenText = text;
    notifyListeners();
  }
}
