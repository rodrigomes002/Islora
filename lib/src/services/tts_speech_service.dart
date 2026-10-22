import 'package:flutter_tts/flutter_tts.dart';

import 'speech_service.dart';

class TtsSpeechService implements SpeechService {
  TtsSpeechService() : _textToSpeech = FlutterTts();

  final FlutterTts _textToSpeech;

  @override
  Future<void> speak(String text) async {
    await _textToSpeech.setLanguage('en-US');
    await _textToSpeech.setSpeechRate(0.45);
    await _textToSpeech.awaitSpeakCompletion(true);
    await _textToSpeech.speak(text);
  }

  @override
  Future<void> stop() async {
    await _textToSpeech.stop();
  }
}
