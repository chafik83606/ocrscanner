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
        return 'Produit introuvable sur Google Play.\n'
            'Créez les produits in-app dans la Play Console :\n'
            '• ocr_scanner_premium_lifetime\n'
            '• ocr_scanner_premium_monthly\n'
            '(statut Actif, même package com.ctre2.ocrscanner)';
      case IapPurchaseResult.error:
        return 'Erreur lors de l\'achat. Réessayez.';
    }
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
