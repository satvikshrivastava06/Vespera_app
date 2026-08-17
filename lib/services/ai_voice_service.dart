import 'package:flutter_tts/flutter_tts.dart';

class AiVoiceService {
  final FlutterTts _flutterTts = FlutterTts();

  AiVoiceService() {
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(0.9);
  }

  Future<void> speak(String text, {Function? onComplete}) async {
    if (onComplete != null) {
      _flutterTts.setCompletionHandler(() {
        onComplete();
      });
    }
    await _flutterTts.speak(text);
  }

  void stop() {
    _flutterTts.stop();
  }
}
