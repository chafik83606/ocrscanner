import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scan_model.dart';

/// Service d'export (TXT, PDF) et de partage.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ─── TXT ──────────────────────────────────────────────────────────────────

  Future<void> exportAsTxt(ScanModel scan) async {
    final file = await _createTempFile('${scan.id}.txt');
    await file.writeAsString(scan.extractedText);
    await Share.shareXFiles([XFile(file.path)], text: scan.title ?? 'OCR Scan');
  }

  // ─── PDF ──────────────────────────────────────────────────────────────────

  Future<void> exportAsPdf(ScanModel scan) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(File(scan.imagePath).readAsBytesSync());

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: scan.title ?? 'Scan OCR'),
          pw.Image(image, height: 300),
          pw.SizedBox(height: 16),
          pw.Text(scan.extractedText),
        ],
      ),
    );

    final file = await _createTempFile('${scan.id}.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], text: scan.title ?? 'OCR Scan');
  }

  /// Ouvre le dialogue d'impression système pour le PDF.
  Future<void> printPdf(ScanModel scan) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [pw.Text(scan.extractedText)],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  // ─── Partage texte brut ───────────────────────────────────────────────────

  Future<void> shareText(String text) async {
    await Share.share(text);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<File> _createTempFile(String filename) async {
    final dir = await getTemporaryDirectory();
    return File(p.join(dir.path, filename));
  }

  /// Sauvegarde une image dans le répertoire persistant de l'app.
  Future<String> saveImagePermanently(String tempPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(p.join(appDir.path, 'scans'));
    if (!scansDir.existsSync()) scansDir.createSync(recursive: true);

    final filename = p.basename(tempPath);
    final destination = p.join(scansDir.path, filename);
    await File(tempPath).copy(destination);
    return destination;
  }
}
