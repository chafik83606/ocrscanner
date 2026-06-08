import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/app_constants.dart';

/// Service d'extraction de texte (OCR) via Google ML Kit.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};

  /// Script ML Kit associé à un code langue BCP-47 supporté.
  TextRecognitionScript scriptForLanguage(String language) {
    return AppConstants.ocrLanguageScripts[language] ??
        TextRecognitionScript.latin;
  }

  TextRecognizer _recognizerFor(String language) {
    final lang = AppConstants.ocrLanguages.containsKey(language)
        ? language
        : 'fr';
    final script = scriptForLanguage(lang);
    return _recognizers.putIfAbsent(
      script,
      () => TextRecognizer(script: script),
    );
  }

  /// Extrait le texte d'une image locale.
  /// [language] : code BCP-47 (fr, en, es, de) → script Latin ML Kit.
  Future<String> extractText(String imagePath, {String language = 'fr'}) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final recognizer = _recognizerFor(language);

    final RecognizedText result = await recognizer.processImage(inputImage);
    return result.text.trim();
  }

  /// Libère les recognizers (optionnel, ex. fermeture app).
  Future<void> dispose() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
    _recognizers.clear();
  }
}
