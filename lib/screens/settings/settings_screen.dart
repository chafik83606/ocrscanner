import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          premium.isPremium ? Icons.star : Icons.star_border,
                          color: premium.isPremium ? Colors.amber : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                premium.isPremium
                                    ? 'Premium actif'
                                    : 'Version gratuite',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                premium.isPremium
                                    ? 'Merci pour votre soutien !'
                                    : '${premium.remainingFreeScans} scans gratuits restants',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!premium.isPremium) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.push('/premium'),
                          child: const Text('Passer en Premium'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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

          // ── Légal ────────────────────────────────────────────────────────
          const _SectionHeader('Informations légales'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, AppConstants.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Conditions d\'utilisation (EULA)'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, AppConstants.termsOfUseUrl),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Suppression des données'),
            subtitle: const Text('Comment demander la suppression de vos données'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(
              context,
              '${AppConstants.privacyPolicyUrl}delete-data.html',
            ),
          ),

          const Divider(),

          // ── À propos ─────────────────────────────────────────────────────
          const _SectionHeader('À propos'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text(AppConstants.appVersion),
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

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
      );
    }
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
