import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/scan_model.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/scan_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<ScanModel>? _results;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanProv = context.watch<ScanProvider>();
    final items = _results ?? scanProv.scans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Rechercher dans les scans…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _results = null);
                    },
                  ),
              ],
              onChanged: (q) async {
                if (q.isEmpty) {
                  setState(() => _results = null);
                } else {
                  final r = await scanProv.search(q);
                  setState(() => _results = r);
                }
              },
            ),
          ),
        ),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Aucun scan sauvegardé'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final scan = items[index];
                return Dismissible(
                  key: ValueKey(scan.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context),
                  onDismissed: (_) =>
                      context.read<ScanProvider>().deleteScan(scan),
                  child: ScanCard(
                    scan: scan,
                    onTap: () => context.push('/result', extra: scan),
                  ),
                );
              },
            ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer ce scan ?'),
            content: const Text(
              'L\'image et le texte seront définitivement supprimés.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
