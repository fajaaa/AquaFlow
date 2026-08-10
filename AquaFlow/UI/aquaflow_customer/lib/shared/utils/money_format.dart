/// Parses a comma- or dot-decimal money string (e.g. "1,35" or "1.35") into
/// a [double], returning null for empty or unparseable input.
double? parseDecimal(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

/// Formats a money value with up to 4 decimal places, trimming trailing
/// zeros down to a 2-decimal floor (e.g. `1.3500` -> `1.35`, `1.0000` ->
/// `1.00`).
String formatMoney(double value) {
  final text = value.toStringAsFixed(4);
  final dotIndex = text.indexOf('.');
  var end = text.length;
  while (end > dotIndex + 3 && text[end - 1] == '0') {
    end--;
  }
  return text.substring(0, end);
}
