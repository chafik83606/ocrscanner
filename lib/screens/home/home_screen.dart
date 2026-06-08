import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/premium_provider.dart';
import '../../providers/scan_provider.dart';
import '../../models/scan_model.dart';
import '../../widgets/scan_card.dart';
import '../../widgets/ad_banner_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    final scanProv = context.watch<ScanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: premium.isPremium
                ? () => context.push('/history')
                : () => context.push('/premium'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Badge Premium / scans restants ──────────────────────────────
          _FreeScansBar(premium: premium),

          // ── Liste des scans récents (Premium) ───────────────────────────
          Expanded(
            child: premium.isPremium && scanProv.scans.isNotEmpty
                ? _ScanList(scans: scanProv.scans)
                : _EmptyState(isPremium: premium.isPremium),
          ),

          // ── Bannière pub (version gratuite) ─────────────────────────────
          if (!premium.isPremium) const AdBannerWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onScanPressed(context, premium),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scanner'),
      ),
    );
  }

  void _onScanPressed(BuildContext context, PremiumProvider premium) {
    if (!premium.canScan) {
      context.push('/premium');
      return;
    }
    context.push('/camera');
  }
}

// ─── Widgets locaux ──────────────────────────────────────────────────────────

class _FreeScansBar extends StatelessWidget {
  const _FreeScansBar({required this.premium});
  final PremiumProvider premium;

  @override
  Widget build(BuildContext context) {
    if (premium.isPremium) {
      return Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.star, size: 16),
            const SizedBox(width: 8),
            Text(
              'Premium actif – scans illimités',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      );
    }

    final remaining = premium.remainingFreeScans;
    return Container(
      color: remaining == 0
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(remaining == 0 ? Icons.lock : Icons.info_outline, size: 16),
          const SizedBox(width: 8),
          Text(
            remaining == 0
                ? 'Limite atteinte – passez en Premium'
                : '$remaining scan(s) gratuit(s) restant(s)',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (remaining == 0) ...[
            const Spacer(),
            TextButton(
              onPressed: () => GoRouter.of(context).push('/premium'),
              child: const Text('Upgrade'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanList extends StatelessWidget {
  const _ScanList({required this.scans});
  final List<ScanModel> scans;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: scans.length,
      itemBuilder: (context, index) => ScanCard(
        scan: scans[index],
        onTap: () => context.push('/result', extra: scans[index]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 80,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isPremium
                ? 'Aucun scan sauvegardé'
                : 'Appuyez sur "Scanner" pour commencer',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
