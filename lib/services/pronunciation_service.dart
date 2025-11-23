// lib/services/pronunciation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PronunciationService {
  static const String _baseUrl =
      'https://api.dictionaryapi.dev/api/v2/entries/en';

  Future<PronunciationResult?> getPronunciation(String word) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$word'));

      if (response.statusCode == 200) {
        return _parsePronunciation(response.body, word);
      } else {
        print('Error in pronunciation API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Pronunciation error: $e');
      return null;
    }
  }

  PronunciationResult? _parsePronunciation(String responseBody, String word) {
    try {
      final jsonResponse = json.decode(responseBody);

      if (jsonResponse is List && jsonResponse.isNotEmpty) {
        final firstEntry = jsonResponse[0];
        final phonetics = firstEntry['phonetics'] as List?;

        if (phonetics != null && phonetics.isNotEmpty) {
          for (var phonetic in phonetics) {
            final text = phonetic['text'] as String?;
            final audioUrl = phonetic['audio'] as String?;

            if (text != null && audioUrl != null && audioUrl.isNotEmpty) {
              return PronunciationResult(
                word: word,
                phoneticText: text,
                audioUrl: audioUrl,
              );
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error parsing pronunciation: $e');
      return null;
    }
  }
}

class PronunciationResult {
  final String word;
  final String phoneticText;
  final String audioUrl;

  PronunciationResult({
    required this.word,
    required this.phoneticText,
    required this.audioUrl,
  });
}
