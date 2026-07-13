import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/services/statement_ingestion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StatementIngestionService service;

  setUp(() {
    service = StatementIngestionService();
  });

  test('ingests credit card sample statement', () async {
    final json = await rootBundle
        .loadString('assets/samples/sample_cc_statement.json');
    final statement = service.ingestJson(json, sourceFileName: 'cc.json');

    expect(statement.account.name, 'Chase Sapphire');
    expect(statement.account.type.name, 'creditCard');
    expect(statement.transactions, hasLength(4));
    expect(statement.totalExpenses, lessThan(0));
    expect(statement.transactions.first.description, isNotEmpty);
  });

  test('ingests bank account sample statement', () async {
    final json = await rootBundle
        .loadString('assets/samples/sample_bank_statement.json');
    final statement = service.ingestJson(json);

    expect(statement.account.type.name, 'bankAccount');
    expect(statement.transactions, hasLength(4));
    expect(statement.totalIncome, greaterThan(0));
  });

  test('supports alternate field names', () {
    const json = '''
    {
      "account_name": "Savings",
      "account_type": "savings",
      "entries": [
        {
          "transaction_date": "2026-01-10",
          "memo": "Coffee shop",
          "debit": 4.50
        }
      ]
    }
    ''';

    final statement = service.ingestJson(json);

    expect(statement.account.name, 'Savings');
    expect(statement.transactions.single.description, 'Coffee shop');
    expect(statement.transactions.single.amount, -4.5);
  });

  test('throws on invalid JSON', () {
    expect(
      () => service.ingestJson('{not json'),
      throwsA(isA<StatementIngestionException>()),
    );
  });

  test('throws when transactions are missing', () {
    expect(
      () => service.ingestJson('{"account": {"name": "Test"}}'),
      throwsA(
        predicate<StatementIngestionException>(
          (e) => e.message.contains('No transactions'),
        ),
      ),
    );
  });
}
