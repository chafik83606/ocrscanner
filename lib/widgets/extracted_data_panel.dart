import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/extracted_field.dart';
import '../providers/premium_provider.dart';
import '../services/text_extraction_service.dart';
import '../utils/app_constants.dart';

/// Panneau d'extraction de données (filtres + recherche par libellé).
class ExtractedDataPanel extends StatefulWidget {
  const ExtractedDataPanel({super.key, required this.text});

  final String text;

  @override
  State<ExtractedDataPanel> createState() => _ExtractedDataPanelState();
}

class _ExtractedDataPanelState extends State<ExtractedDataPanel> {
  final _labelCtrl = TextEditingController();
  final _extractor = TextExtractionService.instance;

  ExtractionFilter? _activeFilter;
  List<String> _filterResults = [];
  List<ExtractedField> _labelResults = [];

  static const int _freeFilterLimit = AppConstants.freeExtractionFilterLimit;
  static const int _freeLabelLimit = AppConstants.freeExtractionLabelLimit;

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    final hasText = widget.text.trim().isNotEmpty;

    if (!hasText) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun texte à analyser.\nScannez un document contenant du texte.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Rechercher un libellé',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex. salaire net, total TTC…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchByLabel(premium),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _searchByLabel(premium),
              icon: const Icon(Icons.search),
              tooltip: 'Rechercher',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TextExtractionService.suggestedLabels
              .map(
                (label) => ActionChip(
                  label: Text(label),
                  onPressed: () {
                    _labelCtrl.text = label;
                    _searchByLabel(premium);
                  },
                ),
              )
              .toList(),
        ),
        if (_labelResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Résultats par libellé'),
          ..._labelResults.map((f) => _FieldTile(field: f)),
        ],
        const SizedBox(height: 16),
        Text('Filtres automatiques', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ExtractionFilter.values.map((filter) {
            final selected = _activeFilter == filter;
            return FilterChip(
              label: Text(_filterLabel(filter)),
              selected: selected,
              onSelected: (_) => _applyFilter(filter, premium),
            );
          }).toList(),
        ),
        if (_filterResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._filterResults.map(
            (value) => ListTile(
              dense: true,
              title: Text(value),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copier',
                onPressed: () => _copy(value),
              ),
            ),
          ),
        ],
        if (!premium.isPremium) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Extraction illimitée avec Premium'),
              subtitle: const Text(
                'Version gratuite : 5 résultats par filtre, 2 recherches par libellé.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/premium'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  void _searchByLabel(PremiumProvider premium) {
    final all = _extractor.findByLabel(widget.text, _labelCtrl.text);
    final limit = premium.isPremium ? all.length : _freeLabelLimit;
    setState(() {
      _labelResults = all.take(limit).toList();
      _activeFilter = null;
      _filterResults = [];
    });
  }

  void _applyFilter(ExtractionFilter filter, PremiumProvider premium) {
    final all = _extractor.applyFilter(widget.text, filter);
    final limit = premium.isPremium ? all.length : _freeFilterLimit;
    setState(() {
      _activeFilter = filter;
      _filterResults = all.take(limit).toList();
      _labelResults = [];
    });
  }

  String _filterLabel(ExtractionFilter filter) => switch (filter) {
        ExtractionFilter.amounts => 'Montants',
        ExtractionFilter.dates => 'Dates',
        ExtractionFilter.emails => 'E-mails',
        ExtractionFilter.phones => 'Téléphones',
      };

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié dans le presse-papiers')),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field});
  final ExtractedField field;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(field.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (field.confidence < 0.8)
              Text(
                'Valeur probable — à vérifier',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copier la valeur',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: field.value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Valeur copiée')),
            );
          },
        ),
      ),
    );
  }
}
