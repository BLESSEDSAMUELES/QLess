import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_preorder_system/main.dart';

void main() {
  testWidgets('QLess initial smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QLessApp());
    await tester.pump();
    expect(find.text('Student Portal'), findsOneWidget);
    expect(find.text('Canteen Kitchen Portal'), findsOneWidget);
  });
}
