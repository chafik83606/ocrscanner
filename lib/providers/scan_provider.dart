import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/scan_model.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart';
import '../services/export_service.dart';

enum ScanStatus { idle, processing, success, error }

/// Gère la liste des scans, l'OCR et les exports.
class ScanProvider extends ChangeNotifier {
  List<ScanModel> _scans = [];
  ScanModel? _current;
  ScanStatus _status = ScanStatus.idle;
  String _errorMsg = '';

  List<ScanModel> get scans => List.unmodifiable(_scans);
  ScanModel? get current => _current;
  ScanStatus get status => _status;
  String get errorMsg => _errorMsg;
  bool get isLoading => _status == ScanStatus.processing;

  Future<void> init() async {
    _scans = await DatabaseService.instance.getAllScans();
    notifyListeners();
  }

  // ─── OCR ──────────────────────────────────────────────────────────────────

  /// Lance l'extraction OCR sur [imagePath].
  /// Retourne le ScanModel résultant (non encore sauvegardé).
  Future<ScanModel?> performOcr(
    String imagePath, {
    String language = 'fr',
  }) async {
    _status = ScanStatus.processing;
    _errorMsg = '';
    notifyListeners();

    try {
      // Copie l'image dans un emplacement permanent
      final permanentPath = await ExportService.instance.saveImagePermanently(
        imagePath,
      );

      final text = await OcrService.instance.extractText(
        permanentPath,
        language: language,
      );

      _current = ScanModel(
        imagePath: permanentPath,
        extractedText: text,
        language: language,
      );

      _status = ScanStatus.success;
      notifyListeners();
      return _current;
    } catch (e) {
      _status = ScanStatus.error;
      _errorMsg = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── Persistance ──────────────────────────────────────────────────────────

  Future<void> saveScan(ScanModel scan) async {
    await DatabaseService.instance.insertScan(scan);
    _scans.insert(0, scan);
    notifyListeners();
  }

  Future<void> deleteScan(ScanModel scan) async {
    await DatabaseService.instance.deleteScan(scan.id);
    // Supprime aussi le fichier image
    final file = File(scan.imagePath);
    if (file.existsSync()) file.deleteSync();
    _scans.removeWhere((s) => s.id == scan.id);
    notifyListeners();
  }

  Future<List<ScanModel>> search(String query) async {
    return DatabaseService.instance.searchScans(query);
  }

  void reset() {
    _status = ScanStatus.idle;
    _current = null;
    notifyListeners();
  }
}
