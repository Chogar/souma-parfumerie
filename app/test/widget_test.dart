import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:souma_parfumerie/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Écran de connexion affiche les titres', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SoumaApp());
    await tester.pump();
    // Attendre la fin du chargement des identifiants mémorisés (LoginCredentialsService).
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Souma Parfumerie'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
