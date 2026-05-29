/// Résultat d'un export PDF (rapports, factures, etc.).
class PdfExportResult {
  const PdfExportResult({this.path, this.error});

  final String? path;
  final Object? error;

  bool get ok => path != null;
}
