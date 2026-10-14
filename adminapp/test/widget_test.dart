import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/main.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Smoke test loads app placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminApp());
    await tester.pumpAndSettle();
    expect(find.text('Slice and Serve Admin'), findsOneWidget);
  });
}
