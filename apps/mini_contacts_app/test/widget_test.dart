import 'package:flutter_test/flutter_test.dart';

import 'package:mini_contacts_app/main.dart';

void main() {
  testWidgets('MiniContacts starts and shows contact list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiniContactsApp());
    await tester.pumpAndSettle();

    expect(find.text('MiniContacts'), findsOneWidget);
    expect(find.text('添加'), findsOneWidget);
  });
}
