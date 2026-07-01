import '../models/extracted_field.dart';

/// Filtres automatiques sur le texte OCR.
enum ExtractionFilter {
  amounts,
  dates,
  emails,
  phones,
}

/// Extraction de données structurées depuis le texte OCR (100 % local).
class TextExtractionService {
  TextExtractionService._();
  static final TextExtractionService instance = TextExtractionService._();

  static final RegExp _amountPattern = RegExp(
    r'(?:\d{1,3}(?:[\s\u00A0]\d{3})+|\d+)[,.]\d{2}\s*(?:€|EUR|\$|USD)?'
    r'|'
    r'(?:\d{1,3}(?:[\s\u00A0]\d{3})+|\d+)\s*(?:€|EUR|\$|USD)',
    caseSensitive: false,
  );

  static final RegExp _datePattern = RegExp(
    r'\b\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\b'
    r'|'
    r'\b\d{4}[/.-]\d{1,2}[/.-]\d{1,2}\b',
  );

  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _phonePattern = RegExp(
    r'(?:\+33|0)[1-9](?:[\s.-]?\d{2}){4}'
    r'|'
    r'\+?\d{1,3}[\s.-]?\(?\d{1,4}\)?[\s.-]?\d{1,4}[\s.-]?\d{1,9}',
  );

  static final RegExp _separatorPattern = RegExp(r'^[:：\-–—|]\s*');

  /// Libellés fréquents sur bulletins de paie / factures.
  static const List<String> suggestedLabels = [
    'salaire net',
    'salaire brut',
    'total TTC',
    'total HT',
    'TVA',
    'date',
    'montant',
    'numéro',
  ];

  List<String> applyFilter(String text, ExtractionFilter filter) {
    final pattern = switch (filter) {
      ExtractionFilter.amounts => _amountPattern,
      ExtractionFilter.dates => _datePattern,
      ExtractionFilter.emails => _emailPattern,
      ExtractionFilter.phones => _phonePattern,
    };
    return pattern
        .allMatches(text)
        .map((m) => m.group(0)!.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Cherche [labelQuery] dans le texte et extrait la valeur associée.
  List<ExtractedField> findByLabel(String text, String labelQuery) {
    final query = labelQuery.trim();
    if (query.isEmpty || text.trim().isEmpty) return [];

    final queryNorm = _normalize(query);
    final lines = text.split('\n');
    final results = <ExtractedField>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final lineNorm = _normalize(line);
      if (!lineNorm.contains(queryNorm)) continue;

      final idx = lineNorm.indexOf(queryNorm);
      var afterLabel = line.substring(idx + query.length).trim();
      afterLabel = afterLabel.replaceFirst(_separatorPattern, '').trim();

      if (afterLabel.isNotEmpty && afterLabel.length < 120) {
        results.add(
          ExtractedField(
            label: query,
            value: afterLabel,
            contextLine: line,
            confidence: 0.9,
          ),
        );
        continue;
      }

      // Valeur sur la ligne suivante (tableaux, colonnes mal OCR).
      if (i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        if (next.isNotEmpty &&
            next.length < 120 &&
            !_looksLikeLabelLine(next)) {
          results.add(
            ExtractedField(
              label: query,
              value: next,
              contextLine: '$line → $next',
              confidence: 0.6,
            ),
          );
        }
      }
    }

    return results;
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ç', 'c');
  }

  bool _looksLikeLabelLine(String line) {
    final letters = RegExp(r'[a-zA-ZÀ-ÿ]').allMatches(line).length;
    final digits = RegExp(r'\d').allMatches(line).length;
    return letters > digits && line.length > 20;
  }
}
