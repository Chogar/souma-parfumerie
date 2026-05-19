import 'package:flutter_test/flutter_test.dart';
import 'package:souma_parfumerie/app.dart';

void main() {
  testWidgets('App démarre', (WidgetTester tester) async {
    await tester.pumpWidget(const SoumaApp());
    expect(find.text('SOUMAPARFUMERIE'), findsOneWidget);
  });
}
