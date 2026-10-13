import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('NextGen Media Example App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NextGenMediaExampleApp());
    expect(find.text('NextGen Media Utility'), findsOneWidget);
  });
}
