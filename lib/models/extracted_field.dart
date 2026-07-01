/// Champ extrait du texte OCR (libellé → valeur).
class ExtractedField {
  const ExtractedField({
    required this.label,
    required this.value,
    this.contextLine,
    this.confidence = 1.0,
  });

  final String label;
  final String value;
  final String? contextLine;

  /// 0.0–1.0 — plus bas si la valeur vient de la ligne suivante.
  final double confidence;
}
