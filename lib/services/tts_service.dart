// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  TTSService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<List<dynamic>> getLanguages() async {
    return await _flutterTts.getLanguages;
  }

  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }
}
