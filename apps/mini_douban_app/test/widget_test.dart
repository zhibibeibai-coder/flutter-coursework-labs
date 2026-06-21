import 'package:flutter_test/flutter_test.dart';
import 'package:mini_douban_app/main.dart';

void main() {
  testWidgets('MiniDouban shows loading state', (WidgetTester tester) async {
    await tester.pumpWidget(const MiniDoubanApp());

    expect(find.text('MiniDouban'), findsOneWidget);
  });
}
