import 'package:customer_app/boutique/models/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:customer_app/boutique/boutique_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Vazirmatn')
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'));
    await font.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Boutique app boots without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      BoutiqueApp(catalogLoader: () async => sampleProducts),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BoutiqueApp), findsOneWidget);
  });
}
