import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Constantes de l'application (clés SharedPreferences, etc.)
class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.14';

  // ─── Extraction de données (limites version gratuite) ───────────────────
  static const int freeExtractionFilterLimit = 5;
  static const int freeExtractionLabelLimit = 2;

  // ─── SharedPreferences keys ───────────────────────────────────────────────
  static const String keyScanCount = 'free_scan_count';
  static const String keyIsPremium = 'is_premium';
  static const String keyOcrLanguage = 'ocr_language';

  // ─── Limites gratuites ────────────────────────────────────────────────────
  static const int freeScansAllowed = 5;

  // ─── Produits in-app : voir lib/utils/iap_product_ids.dart ───────────────

  // ─── Liens légaux (obligatoires App Store pour abonnements) ─────────────
  static const String privacyPolicyUrl =
      'https://chafik83606.github.io/ocrscanner/';

  /// EULA standard Apple (ou remplacer par une URL personnalisée).
  static const String termsOfUseUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  // ─── Langues OCR supportées ───────────────────────────────────────────────
  static const Map<String, String> ocrLanguages = {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
  };

  /// Script ML Kit par langue (FR/EN/ES/DE → alphabet latin).
  static const Map<String, TextRecognitionScript> ocrLanguageScripts = {
    'fr': TextRecognitionScript.latin,
    'en': TextRecognitionScript.latin,
    'es': TextRecognitionScript.latin,
    'de': TextRecognitionScript.latin,
  };

  /// Texte d'aide affiché dans les paramètres.
  static const String ocrLanguageHint =
      'Modèle latin ML Kit — détection automatique FR, EN, ES, DE';

  // ─── Base de données SQLite ───────────────────────────────────────────────
  static const String dbName = 'ocr_scanner.db';
  static const int dbVersion = 1;
  static const String tableName = 'scans';
}
