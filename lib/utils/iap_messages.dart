import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../models/iap_result.dart';

/// Messages utilisateur pour les achats in-app.
class IapMessages {
  IapMessages._();

  static String purchase(IapPurchaseResult result) {
    switch (result) {
      case IapPurchaseResult.success:
        return 'Merci ! Premium est maintenant actif.';
      case IapPurchaseResult.cancelled:
        return 'Achat annulé.';
      case IapPurchaseResult.unavailable:
        return 'Boutique indisponible. Réessayez plus tard.';
      case IapPurchaseResult.productNotFound:
        return _productNotFoundMessage();
      case IapPurchaseResult.error:
        return 'Erreur lors de l\'achat. Réessayez.';
    }
  }

  static String _productNotFoundMessage() {
    if (!kIsWeb && Platform.isIOS) {
      return 'Offre Premium momentanément indisponible. '
          'Vérifiez votre connexion et réessayez.';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'Produit introuvable sur Google Play.\n'
          'Créez les produits in-app dans la Play Console :\n'
          '• ocr_scanner_premium_timelife\n'
          '• ocr_scanner_premium_30j\n'
          '(statut Actif, même package com.ctre2.ocrscanner)';
    }
    return 'Offre Premium indisponible. Réessayez plus tard.';
  }

  static String restore(IapRestoreResult result) {
    switch (result) {
      case IapRestoreResult.restored:
        return 'Achats restaurés — Premium activé.';
      case IapRestoreResult.alreadyPremium:
        return 'Premium est déjà actif sur cet appareil.';
      case IapRestoreResult.nothingToRestore:
        return 'Aucun achat Premium trouvé pour ce compte.';
      case IapRestoreResult.unavailable:
        return 'Boutique indisponible. Réessayez plus tard.';
    }
  }
}
