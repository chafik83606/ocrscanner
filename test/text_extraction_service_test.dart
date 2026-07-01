import 'package:ocr_scanner/services/text_extraction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final extractor = TextExtractionService.instance;

  group('TextExtractionService', () {
    test('findByLabel extrait la valeur sur la même ligne', () {
      const text = 'Salaire net : 2 450,00 €\nAutre ligne';
      final results = extractor.findByLabel(text, 'salaire net');
      expect(results, isNotEmpty);
      expect(results.first.value, contains('2 450'));
    });

    test('findByLabel extrait la valeur sur la ligne suivante', () {
      const text = 'Total TTC\n1 234,56 €';
      final results = extractor.findByLabel(text, 'total TTC');
      expect(results, isNotEmpty);
      expect(results.first.value, contains('1 234'));
    });

    test('applyFilter montants détecte les euros', () {
      const text = 'Montant: 99,99 € et aussi 1 200,00 EUR';
      final amounts = extractor.applyFilter(text, ExtractionFilter.amounts);
      expect(amounts.length, greaterThanOrEqualTo(2));
    });

    test('applyFilter dates détecte le format français', () {
      const text = 'Date: 01/07/2026';
      final dates = extractor.applyFilter(text, ExtractionFilter.dates);
      expect(dates, contains('01/07/2026'));
    });

    test('applyFilter emails', () {
      const text = 'Contact: support@example.com';
      final emails = extractor.applyFilter(text, ExtractionFilter.emails);
      expect(emails, contains('support@example.com'));
    });
  });
}
