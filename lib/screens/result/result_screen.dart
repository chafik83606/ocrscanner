import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/scan_model.dart';
import '../../providers/premium_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/extracted_data_panel.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.scan});
  final ScanModel? scan;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late ScanModel _scan;
  bool _saved = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scan =
        widget.scan ??
        ScanModel(imagePath: '', extractedText: '', language: 'fr');
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoSave());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _maybeAutoSave() async {
    if (_saved || !mounted) return;
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium || _scan.extractedText.trim().isEmpty) return;
    await _saveScan(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Texte'),
            Tab(text: 'Données'),
          ],
        ),
        actions: [
          if (premium.isPremium && !_saved)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Sauvegarder',
              onPressed: () => _saveScan(),
            ),
          if (_saved)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.check, color: Colors.green),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTextTab(context, premium),
          ExtractedDataPanel(text: _scan.extractedText),
        ],
      ),
    );
  }

  Widget _buildTextTab(BuildContext context, PremiumProvider premium) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (premium.isPremium) ...[
            Text('Exporter', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  onPressed: () => ExportService.instance.exportAsPdf(_scan),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('TXT'),
                  onPressed: () => ExportService.instance.exportAsTxt(_scan),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimer'),
                  onPressed: () => ExportService.instance.printPdf(_scan),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                  onPressed: () =>
                      ExportService.instance.shareText(_scan.extractedText),
                ),
              ],
            ),
          ] else ...[
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
    );
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _scan.extractedText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texte copié dans le presse-papiers')),
    );
  }

  Future<void> _saveScan({bool silent = false}) async {
    var scanToSave = _scan;
    if (scanToSave.title == null || scanToSave.title!.trim().isEmpty) {
      scanToSave = scanToSave.copyWith(
        title: _autoTitle(scanToSave.extractedText),
      );
    }
    await context.read<ScanProvider>().saveScan(scanToSave);
    if (!mounted) return;
    setState(() {
      _scan = scanToSave;
      _saved = true;
    });
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan sauvegardé')),
      );
    }
  }

  String _autoTitle(String text) {
    final line = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .cast<String>()
        .firstOrNull;
    if (line == null) {
      final now = DateTime.now();
      return 'Scan ${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/${now.year}';
    }
    return line.length > 48 ? '${line.substring(0, 48)}…' : line;
  }
}
