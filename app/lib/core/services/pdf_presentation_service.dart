import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Résultat de l'enregistrement / ouverture d'un PDF.
class PdfPresentResult {
  const PdfPresentResult({
    required this.saved,
    this.file,
    this.opened = false,
    this.error,
  });

  final bool saved;
  final File? file;
  final bool opened;
  final Object? error;

  bool get ok => saved;
}

/// Enregistre un PDF et tente de l'ouvrir (macOS / Windows / Linux).
class PdfPresentationService {
  static Future<PdfPresentResult> present({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final name = filename.endsWith('.pdf') ? filename : '$filename.pdf';
      final file = await _saveToExports(name, bytes);
      if (file == null) {
        return const PdfPresentResult(
          saved: false,
          error: 'Impossible d\'enregistrer le fichier',
        );
      }

      var opened = false;
      try {
        opened = await _openFile(file);
      } catch (e) {
        // Fichier enregistré : on tentera le partage système en secours.
        try {
          await Printing.sharePdf(
            bytes: bytes,
            filename: name,
          );
          opened = true;
        } catch (_) {
          return PdfPresentResult(saved: true, file: file, opened: false);
        }
      }
      return PdfPresentResult(saved: true, file: file, opened: opened);
    } catch (e) {
      return PdfPresentResult(saved: false, error: e);
    }
  }

  static Future<File?> _saveToExports(String name, Uint8List bytes) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/Souma Parfumerie/exports');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final safeName = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<bool> _openFile(File file) async {
    final path = file.path;
    if (Platform.isMacOS) {
      var r = await Process.run('open', [path]);
      if (r.exitCode == 0) return true;
      r = await Process.run('open', ['-R', path]);
      return r.exitCode == 0;
    }
    if (Platform.isWindows) {
      final r = await Process.run(
        'cmd',
        ['/c', 'start', '', path],
        runInShell: true,
      );
      return r.exitCode == 0;
    }
    if (Platform.isLinux) {
      final r = await Process.run('xdg-open', [path]);
      return r.exitCode == 0;
    }
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: file.uri.pathSegments.last,
    );
    return true;
  }
}
