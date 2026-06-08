import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

/// Gère le compteur de scans gratuits et le statut Premium.
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  // ─── Compteur scans gratuits ──────────────────────────────────────────────

  Future<int> getScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyScanCount) ?? 0;
  }

  Future<void> incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(AppConstants.keyScanCount) ?? 0;
    await prefs.setInt(AppConstants.keyScanCount, count + 1);
  }

  Future<bool> canScanForFree() async {
    final count = await getScanCount();
    return count < AppConstants.freeScansAllowed;
  }

  // ─── Statut Premium ───────────────────────────────────────────────────────

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsPremium) ?? false;
  }

  /// Appelé après un achat in-app validé.
  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsPremium, value);
  }

  // ─── Langue OCR préférée ──────────────────────────────────────────────────

  Future<String> getOcrLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyOcrLanguage) ?? 'fr';
  }

  Future<void> setOcrLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyOcrLanguage, langCode);
  }
}
