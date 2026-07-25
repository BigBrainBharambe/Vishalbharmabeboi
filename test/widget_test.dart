import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Import statement'), findsOneWidget);
  });
}
