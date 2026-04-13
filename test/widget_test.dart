import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/main.dart';

void main() {
  testWidgets('LeastPrice app renders root shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const LeastPriceApp(
        firebaseBootstrapNotice: 'test bootstrap',
      ),
    );

    expect(find.byType(LeastPriceApp), findsOneWidget);
  });
}
