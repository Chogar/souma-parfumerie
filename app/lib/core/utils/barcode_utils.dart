/// Normalisation des codes-barres (scanner, saisie manuelle).
class BarcodeUtils {
  BarcodeUtils._();

  /// Retire espaces, retours chariot et caractères de contrôle.
  static String normalize(String raw) {
    return raw
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
  }

  /// Variantes courantes (EAN-13 / zéros en tête).
  static List<String> variants(String normalized) {
    if (normalized.isEmpty) return const [];

    final set = <String>{normalized};

    final noLeadingZeros = normalized.replaceFirst(RegExp(r'^0+'), '');
    if (noLeadingZeros.isNotEmpty) set.add(noLeadingZeros);

    if (normalized.length == 12 && RegExp(r'^\d+$').hasMatch(normalized)) {
      set.add('0$normalized');
    }
    if (noLeadingZeros.length == 12 && RegExp(r'^\d+$').hasMatch(noLeadingZeros)) {
      set.add('0$noLeadingZeros');
    }

    return set.toList();
  }
}
