import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/scan_model.dart';
import '../../providers/premium_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/ad_banner_widget.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.scan});
  final ScanModel? scan;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ScanModel _scan;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _scan =
        widget.scan ??
        ScanModel(imagePath: '', extractedText: '', language: 'fr');
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat'),
        actions: [
          if (premium.isPremium && !_saved)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Sauvegarder',
              onPressed: _saveScan,
            ),
          if (_saved)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.check, color: Colors.green),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image scannée ──────────────────────────────────────
                  if (_scan.imagePath.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_scan.imagePath),
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Texte extrait ──────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Texte extrait',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copier',
                                onPressed: _copyText,
                              ),
                            ],
                          ),
                          const Divider(),
                          SelectableText(
                            _scan.extractedText.isEmpty
                                ? '(Aucun texte détecté)'
                                : _scan.extractedText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Boutons d'export (Premium) ─────────────────────────
                  if (premium.isPremium) ...[
                    Text(
                      'Exporter',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                          onPressed: () =>
                              ExportService.instance.exportAsPdf(_scan),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.text_snippet),
                          label: const Text('TXT'),
                          onPressed: () =>
                              ExportService.instance.exportAsTxt(_scan),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.print),
                          label: const Text('Imprimer'),
                          onPressed: () =>
                              ExportService.instance.printPdf(_scan),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Partager'),
                          onPressed: () => ExportService.instance.shareText(
                            _scan.extractedText,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Bouton upgrade + partage texte uniquement
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Partager le texte'),
                      onPressed: () =>
                          ExportService.instance.shareText(_scan.extractedText),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text('Passer en Premium pour exporter'),
                      onPressed: () => context.push('/premium'),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (!premium.isPremium) const AdBannerWidget(),
        ],
      ),
    );
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _scan.extractedText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texte copié dans le presse-papiers')),
    );
  }

  Future<void> _saveScan() async {
    await context.read<ScanProvider>().saveScan(_scan);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Scan sauvegardé')));
  }
}
