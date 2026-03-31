import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService instance = TtsService._init();

  TtsService._init();

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _onCompleted?.call();
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _onCompleted?.call();
        print('⚠️ TTS error: $msg');
      });

      print('✅ TTS inicializado (es-ES)');
    } catch (e) {
      print('⚠️ Error inicializando TTS: $e');
    }
  }

  void Function()? _onCompleted;

  Future<void> speak(String text, {void Function()? onCompleted}) async {
    _onCompleted = onCompleted;
    if (_isSpeaking) await stop();
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _isSpeaking = false;
    _onCompleted = null;
    await _tts.stop();
  }

  Future<void> dispose() async {
    await stop();
  }
}
