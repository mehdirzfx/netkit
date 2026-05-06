import 'package:flutter_test/flutter_test.dart';
import 'package:netkit/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IranToolkitApp());
    expect(find.byType(IranToolkitApp), findsOneWidget);
  });
}