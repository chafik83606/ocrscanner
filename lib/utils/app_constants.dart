import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Constantes de l'application (clés SharedPreferences, IDs AdMob, etc.)
class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.6';

  // ─── SharedPreferences keys ───────────────────────────────────────────────
  static const String keyScanCount = 'free_scan_count';
  static const String keyIsPremium = 'is_premium';
  static const String keyOcrLanguage = 'ocr_language';

  // ─── Limites gratuites ────────────────────────────────────────────────────
  static const int freeScansAllowed = 5;

  // ─── Produits in-app ─────────────────────────────────────────────────────
  /// Achat unique
  static const String iapOneTimePurchase = 'ocr_scanner_premium_lifetime';

  /// Abonnement mensuel
  static const String iapMonthlySubscription = 'ocr_scanner_premium_monthly';

  // ─── AdMob IDs (remplacer par les vrais IDs en production) ────────────────
  /// App ID Android — voir aussi android/app/src/main/res/values/strings.xml
  static const String admobAppIdAndroid =
      'ca-app-pub-3940256099942544~3347511713';

  /// App ID iOS — voir aussi ios/Runner/Info.plist (GADApplicationIdentifier)
  static const String admobAppIdIos =
      'ca-app-pub-3940256099942544~1458002511';

  /// Bannière - Android test ID
  static const String admobBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  /// Bannière - iOS test ID
  static const String admobBannerIos =
      'ca-app-pub-3940256099942544/2934735716';

  /// Interstitiel - Android test ID
  static const String admobInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';

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
