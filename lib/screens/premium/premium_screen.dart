import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/iap_result.dart';
import '../../providers/premium_provider.dart';
import '../../services/iap_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/iap_messages.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _busy = false;
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() => _loadingProducts = true);
    await IapService.instance.loadProducts();
    if (mounted) setState(() => _loadingProducts = false);
  }

  @override
  Widget build(BuildContext context) {
    final iap = IapService.instance;
    final lifetime = iap.product(AppConstants.iapOneTimePurchase);
    final monthly = iap.product(AppConstants.iapMonthlySubscription);
    final productsReady = iap.hasLifetime && iap.hasMonthly;

    return Scaffold(
      appBar: AppBar(title: const Text('Passer en Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.star_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'OCR Scanner Premium',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ..._features.map(
              (f) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(f),
              ),
            ),
            const SizedBox(height: 24),
            if (_loadingProducts)
              const Center(child: CircularProgressIndicator())
            else if (!productsReady) ...[
              Text(
                'Les offres Premium se chargent depuis l\'App Store. '
                'Vérifiez votre connexion puis réessayez.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _refreshProducts,
                child: const Text('Réessayer'),
              ),
            ] else ...[
              _productCard(
                title: lifetime?.title ?? 'Premium à vie',
                subtitle: 'Achat unique, accès permanent',
                price: lifetime?.price ?? '9,99 €',
                buttonLabel: 'Achat unique – ${lifetime?.price ?? '9,99 €'} (à vie)',
                filled: true,
                onPressed: _busy
                    ? null
                    : () => _purchase(
                          context.read<PremiumProvider>().buyLifetime,
                        ),
              ),
              const SizedBox(height: 16),
              _productCard(
                title: monthly?.title ?? 'Premium mensuel',
                subtitle: 'Abonnement avec renouvellement automatique — 1 mois',
                price: monthly?.price ?? '1,99 € / mois',
                buttonLabel:
                    'Abonnement – ${monthly?.price ?? '1,99 €'} / mois',
                filled: false,
                onPressed: _busy
                    ? null
                    : () => _purchase(
                          context.read<PremiumProvider>().buyMonthly,
                        ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : () => _restore(context.read()),
              child: const Text('Restaurer mes achats'),
            ),
            const SizedBox(height: 16),
            Text(
              'L\'abonnement « Premium mensuel » se renouvelle automatiquement '
              'chaque mois au prix indiqué, sauf annulation au moins 24 h avant '
              'la fin de la période en cours. Gérez ou annulez l\'abonnement '
              'dans Réglages > identifiant Apple > Abonnements.',
              textAlign: TextAlign.center,
              style: _legalStyle(context),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                _legalLink(context, 'Politique de confidentialité',
                    AppConstants.privacyPolicyUrl),
                Text('•', style: _legalStyle(context)),
                _legalLink(
                  context,
                  'Conditions d\'utilisation (EULA)',
                  AppConstants.termsOfUseUrl,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard({
    required String title,
    required String subtitle,
    required String price,
    required String buttonLabel,
    required bool filled,
    required VoidCallback? onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              'Prix : $price',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (filled)
              FilledButton(
                onPressed: onPressed,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonLabel),
              )
            else
              OutlinedButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legalLink(BuildContext context, String label, String url) {
    return InkWell(
      onTap: () => _openUrl(url),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
      ),
    );
  }

  TextStyle? _legalStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
      );
    }
  }

  Future<void> _purchase(
    Future<IapPurchaseResult> Function() buy,
  ) async {
    setState(() => _busy = true);
    final result = await buy();
    if (!mounted) return;
    setState(() => _busy = false);

    final premium = context.read<PremiumProvider>();
    await premium.reloadPremium();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(IapMessages.purchase(result))),
    );

    if (result == IapPurchaseResult.success && premium.isPremium) {
      context.pop();
    } else if (result == IapPurchaseResult.productNotFound) {
      await _refreshProducts();
    }
  }

  Future<void> _restore(PremiumProvider premium) async {
    setState(() => _busy = true);
    final result = await premium.restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(IapMessages.restore(result))),
    );

    if (result == IapRestoreResult.restored ||
        result == IapRestoreResult.alreadyPremium) {
      context.pop();
    }
  }

  static const List<String> _features = [
    'Scans illimités',
    'Historique complet (image + texte)',
    'Export PDF, TXT, impression',
    'Recherche dans les scans',
    'Multi-langues : FR, EN, ES, DE',
    'Suppression des publicités',
  ];
}
