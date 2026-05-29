import 'package:flutter_test/flutter_test.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/features/reports/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = StoreSettings(
    nameFr: 'Souma',
    nameAr: 'سوما',
    address: 'Ndjamena',
  );

  test('build synthesis PDF bytes', () async {
    final bytes = await ExportService.buildReportPdfBytes(
      store: store,
      summary: {'revenue': 100000, 'transactions': 5, 'avg_basket': 20000},
      top: [
        {'name_fr': 'Produit A', 'qty_sold': 3, 'revenue': 50000},
      ],
      from: DateTime(2026, 5, 1),
      to: DateTime(2026, 5, 19),
      dailyRevenue: [
        {'day': DateTime(2026, 5, 1), 'revenue': 10000},
        {'day': DateTime(2026, 5, 2), 'revenue': 20000},
      ],
      monthlyRevenue: [
        {'month': DateTime(2026, 1, 1), 'revenue': 50000},
        {'month': DateTime(2026, 2, 1), 'revenue': 60000},
      ],
      returnStats: {
        'requested': 1,
        'pending': 0,
        'approved': 1,
        'rejected': 0,
        'approved_amount': 5000,
      },
    );
    expect(bytes.isNotEmpty, true);
  });
}
