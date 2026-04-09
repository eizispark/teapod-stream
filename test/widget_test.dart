import 'package:flutter_test/flutter_test.dart';
import 'package:teapodstream/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TeapodApp());
    expect(find.byType(TeapodApp), findsOneWidget);
  });
}
