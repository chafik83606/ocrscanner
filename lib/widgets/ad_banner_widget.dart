import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/app_constants.dart';

/// Bannière AdMob affichée en bas d'écran pour les utilisateurs gratuits.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  static String get _adUnitId => Platform.isIOS
      ? AppConstants.admobBannerIos
      : AppConstants.admobBannerAndroid;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _ad = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
