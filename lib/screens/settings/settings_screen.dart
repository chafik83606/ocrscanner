import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/premium_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/iap_messages.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // ── Statut Premium ───────────────────────────────────────────────
          const _SectionHeader('Abonnement'),
          ListTile(
            leading: Icon(
              premium.isPremium ? Icons.star : Icons.star_border,
              color: premium.isPremium ? Colors.amber : null,
            ),
            title: Text(
              premium.isPremium ? 'Premium actif' : 'Version gratuite',
            ),
            subtitle: premium.isPremium
                ? const Text('Merci pour votre soutien !')
                : Text('${premium.remainingFreeScans} scans gratuits restants'),
            trailing: premium.isPremium
                ? null
                : FilledButton(
                    onPressed: () => context.push('/premium'),
                    child: const Text('Upgrade'),
                  ),
          ),

          const Divider(),

          // ── Langue OCR (Premium uniquement) ──────────────────────────────
          const _SectionHeader('Reconnaissance OCR'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue du document'),
            subtitle: Text(
              premium.isPremium
                  ? '${AppConstants.ocrLanguages[premium.language] ?? premium.language}\n${AppConstants.ocrLanguageHint}'
                  : AppConstants.ocrLanguageHint,
            ),
            isThreeLine: premium.isPremium,
            trailing: premium.isPremium
                ? const Icon(Icons.chevron_right)
                : const Icon(Icons.lock, size: 18),
            onTap: premium.isPremium
                ? () => _pickLanguage(context, premium)
                : () => context.push('/premium'),
          ),

          const Divider(),

          // ── À propos ─────────────────────────────────────────────────────
          const _SectionHeader('À propos'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.1'),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restaurer les achats'),
            onTap: () async {
              final result = await premium.restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(IapMessages.restore(result))),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(
    BuildContext context,
    PremiumProvider premium,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choisir la langue OCR'),
        children: AppConstants.ocrLanguages.entries
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, e.key),
                child: Text(e.value),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) await premium.setLanguage(selected);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
