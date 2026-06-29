import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/iap_result.dart';
import '../utils/iap_product_ids.dart';
import 'premium_service.dart';

/// Service d'achats in-app (achat unique + abonnement mensuel).
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  static final Set<String> _productIds = IapProductIds.all;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<IapPurchaseResult>? _pendingPurchase;

  final Map<String, ProductDetails> _products = {};
  bool _storeAvailable = false;

  Map<String, ProductDetails> get products => Map.unmodifiable(_products);
  bool get storeAvailable => _storeAvailable;
  bool get hasLifetime => _products.containsKey(IapProductIds.lifetime);
  bool get hasMonthly => _products.containsKey(IapProductIds.monthly);

  ProductDetails? product(String id) => _products[id];

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

  /// Charge les produits depuis l'App Store / Google Play (avec retry).
  Future<void> loadProducts({int retries = 3}) async {
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      _products.clear();
      return;
    }

    for (var attempt = 0; attempt < retries; attempt++) {
      final response = await _iap.queryProductDetails(_productIds);
      _products
        ..clear()
        ..addEntries(
          response.productDetails.map((p) => MapEntry(p.id, p)),
        );

      if (_products.isNotEmpty) return;

      if (attempt < retries - 1) {
        await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
      }
    }
  }

  Future<void> _handlePurchase(
    PurchaseDetails purchase,
    VoidCallback onPurchased,
  ) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
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

  Future<IapPurchaseResult> buyLifetime() => _buy(IapProductIds.lifetime);

  Future<IapPurchaseResult> buyMonthly() => _buy(IapProductIds.monthly);

  Future<IapRestoreResult> restorePurchases() async {
    if (!await _iap.isAvailable()) return IapRestoreResult.unavailable;

    final wasPremium = await PremiumService.instance.isPremium();
    await _iap.restorePurchases();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final isPremium = await PremiumService.instance.isPremium();
    if (isPremium && !wasPremium) return IapRestoreResult.restored;
    if (isPremium) return IapRestoreResult.alreadyPremium;
    return IapRestoreResult.nothingToRestore;
  }

  Future<IapPurchaseResult> _buy(String productId) async {
    if (!await _iap.isAvailable()) return IapPurchaseResult.unavailable;

    if (!_products.containsKey(productId)) {
      await loadProducts();
    }

    final details = _products[productId];
    if (details == null) return IapPurchaseResult.productNotFound;

    _pendingPurchase = Completer<IapPurchaseResult>();
    final purchaseParam = PurchaseParam(productDetails: details);
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
