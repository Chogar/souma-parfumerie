import 'package:flutter_test/flutter_test.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/utils/intl_locale_init.dart';
import 'package:souma_parfumerie/features/reports/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = StoreSettings(nameFr: 'Souma', nameAr: 'سوما');

  test('synthesis PDF save and present', () async {
    await IntlLocaleInit.ensureFrench();
    final bytes = await ExportService.buildReportPdfBytes(
      store: store,
      summary: {
        'revenue': 76700,
        'transactions': 2,
        'avg_basket': 38350,
      },
      top: [
        {
          'name_fr': 'Parfum Test',
          'qty_sold': 2,
          'revenue': 76700,
        },
      ],
      from: DateTime(2026, 5, 24),
      to: DateTime(2026, 5, 24),
      dailyRevenue: [
        {'day': '2026-05-24', 'revenue': 76700, 'transactions': 2},
      ],
      monthlyRevenue: [
        {'month': '2026-05-01 00:00:00.000Z', 'revenue': 76700},
      ],
      returnStats: {
        'requested': 2,
        'pending': 0,
        'approved': 2,
        'rejected': 0,
        'approved_amount': 10000,
      },
    );
    expect(bytes.length, greaterThan(1000));
  });
}
