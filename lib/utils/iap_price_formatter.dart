import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

/// Formate les prix IAP à partir des données StoreKit (rawPrice + devise).
class IapPriceFormatter {
  IapPriceFormatter._();

  /// Prix affiché (ex. « 9,99 € ») — ne pas utiliser [ProductDetails.price]
  /// qui peut afficher « $US » en Sandbox alors que la devise réelle est EUR.
  static String format(ProductDetails product) {
    final code = product.currencyCode.toUpperCase();
    if (code == 'EUR') {
      return NumberFormat.currency(
        locale: 'fr_FR',
        symbol: '€',
        decimalDigits: 2,
      ).format(product.rawPrice);
    }
    return NumberFormat.currency(
      locale: 'fr_FR',
      name: code,
      decimalDigits: 2,
    ).format(product.rawPrice);
  }

  static String formatMonthly(ProductDetails product) =>
      '${format(product)} / mois';

  static String lifetimeButton(ProductDetails product) =>
      'Achat unique – ${format(product)} (à vie)';

  static String monthlyButton(ProductDetails product) =>
      'Abonnement – ${formatMonthly(product)}';

}
