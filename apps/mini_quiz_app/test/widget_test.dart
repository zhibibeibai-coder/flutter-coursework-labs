import 'package:flutter_test/flutter_test.dart';

import 'package:mini_quiz_app/main.dart';

void main() {
  testWidgets('MiniQuiz starts and loads question controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiniQuizApp());
    await tester.pumpAndSettle();

    expect(find.text('MiniQuiz'), findsOneWidget);
    expect(find.text('True'), findsOneWidget);
    expect(find.text('False'), findsOneWidget);
    expect(find.text('提示'), findsOneWidget);
  });
}
