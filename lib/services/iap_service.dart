import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/iap_result.dart';
import '../utils/app_constants.dart';
import 'premium_service.dart';

/// Service d'achats in-app (achat unique + abonnement mensuel).
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<IapPurchaseResult>? _pendingPurchase;

  /// Démarre l'écoute du stream d'achats. À appeler au démarrage.
  void startListening(VoidCallback onPurchased) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        await _handlePurchase(purchase, onPurchased);
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _handlePurchase(
    PurchaseDetails purchase,
    VoidCallback onPurchased,
  ) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // TODO: valider le reçu côté serveur en production
        await PremiumService.instance.setPremium(true);
        onPurchased();
        _completePending(IapPurchaseResult.success);
      case PurchaseStatus.canceled:
        _completePending(IapPurchaseResult.cancelled);
      case PurchaseStatus.error:
        _completePending(IapPurchaseResult.error);
      case PurchaseStatus.pending:
        break;
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void _completePending(IapPurchaseResult result) {
    if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
      _pendingPurchase!.complete(result);
    }
    _pendingPurchase = null;
  }

  /// Lance l'achat unique (lifetime).
  Future<IapPurchaseResult> buyLifetime() =>
      _buy(AppConstants.iapOneTimePurchase);

  /// Lance l'abonnement mensuel (non-consommable côté plugin).
  Future<IapPurchaseResult> buyMonthly() =>
      _buy(AppConstants.iapMonthlySubscription);

  /// Restaure les achats précédents et indique le résultat.
  Future<IapRestoreResult> restorePurchases() async {
    final available = await _iap.isAvailable();
    if (!available) return IapRestoreResult.unavailable;

    final wasPremium = await PremiumService.instance.isPremium();
    await _iap.restorePurchases();

    // Laisse le temps au purchaseStream de traiter les achats restaurés.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final isPremium = await PremiumService.instance.isPremium();
    if (isPremium && !wasPremium) return IapRestoreResult.restored;
    if (isPremium) return IapRestoreResult.alreadyPremium;
    return IapRestoreResult.nothingToRestore;
  }

  Future<IapPurchaseResult> _buy(String productId) async {
    final available = await _iap.isAvailable();
    if (!available) return IapPurchaseResult.unavailable;

    final response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return IapPurchaseResult.productNotFound;
    }

    _pendingPurchase = Completer<IapPurchaseResult>();
    final purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );

    // Abonnements et achats uniques : buyNonConsumable (API officielle du plugin).
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _pendingPurchase = null;
      return IapPurchaseResult.unavailable;
    }

    try {
      return await _pendingPurchase!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _pendingPurchase = null;
          return IapPurchaseResult.error;
        },
      );
    } catch (_) {
      _pendingPurchase = null;
      return IapPurchaseResult.error;
    }
  }
}
