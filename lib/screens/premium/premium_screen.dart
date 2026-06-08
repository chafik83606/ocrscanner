import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/iap_result.dart';
import '../../providers/premium_provider.dart';
import '../../utils/iap_messages.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();

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
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _busy ? null : () => _purchase(premium.buyLifetime),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Achat unique – 4,99 €  (à vie)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : () => _purchase(premium.buyMonthly),
              child: const Text('Abonnement – 1,99 € / mois'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : () => _restore(premium),
              child: const Text('Restaurer mes achats'),
            ),
            const SizedBox(height: 24),
            Text(
              'L\'abonnement se renouvelle automatiquement à moins d\'être '
              'annulé 24h avant la fin de la période en cours. Les prix '
              's\'entendent TTC.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
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
