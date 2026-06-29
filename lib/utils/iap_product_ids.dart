import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// IDs des achats in-app — différents sur App Store et Google Play.
class IapProductIds {
  IapProductIds._();

  // App Store Connect
  static const String iosLifetime = 'ocr_scanner_premium_timelife';
  static const String iosMonthly = 'ocr_scanner_premium_30j';

  // Google Play Console
  static const String androidLifetime = 'ocr_scanner_premium_lifetime';
  static const String androidMonthly = 'ocr_scanner_premium_monthly';

  static String get lifetime {
    if (kIsWeb) return androidLifetime;
    return Platform.isIOS ? iosLifetime : androidLifetime;
  }

  static String get monthly {
    if (kIsWeb) return androidMonthly;
    return Platform.isIOS ? iosMonthly : androidMonthly;
  }

  static Set<String> get all => {lifetime, monthly};
}
