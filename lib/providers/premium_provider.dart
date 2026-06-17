import 'package:flutter/foundation.dart';

import '../models/iap_result.dart';
import '../services/premium_service.dart';
import '../services/iap_service.dart';
import '../utils/app_constants.dart';

/// Expose l'état Premium et le compteur de scans gratuits.
class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  int _scanCount = 0;
  String _language = 'fr';

  bool get isPremium => _isPremium;
  int get scanCount => _scanCount;
  String get language => _language;

  bool get canScan =>
      _isPremium || _scanCount < AppConstants.freeScansAllowed;

  int get remainingFreeScans =>
      (AppConstants.freeScansAllowed - _scanCount).clamp(
        0,
        AppConstants.freeScansAllowed,
      );

  /// Initialisation au démarrage.
  Future<void> init() async {
    await reloadPremium();
    await IapService.instance.loadProducts();

    IapService.instance.startListening(() async {
      await reloadPremium();
    });

    notifyListeners();
  }

  /// Recharge le statut Premium et le compteur depuis le stockage local.
  Future<void> reloadPremium() async {
    _isPremium = await PremiumService.instance.isPremium();
    _scanCount = await PremiumService.instance.getScanCount();
    _language = await PremiumService.instance.getOcrLanguage();
    notifyListeners();
  }

  /// Appelé après chaque scan réussi.
  Future<void> recordScan() async {
    if (!_isPremium) {
      await PremiumService.instance.incrementScanCount();
      _scanCount = await PremiumService.instance.getScanCount();
      notifyListeners();
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (!AppConstants.ocrLanguages.containsKey(langCode)) return;
    _language = langCode;
    await PremiumService.instance.setOcrLanguage(langCode);
    notifyListeners();
  }

  Future<IapPurchaseResult> buyLifetime() =>
      IapService.instance.buyLifetime();

  Future<IapPurchaseResult> buyMonthly() => IapService.instance.buyMonthly();

  Future<IapRestoreResult> restorePurchases() async {
    final result = await IapService.instance.restorePurchases();
    await reloadPremium();
    return result;
  }

  @override
  void dispose() {
    IapService.instance.stopListening();
    super.dispose();
  }
}
