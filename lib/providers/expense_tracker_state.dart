import 'package:flutter/foundation.dart';

import '../models/account_statement.dart';
import '../models/transaction.dart';
import '../services/statement_ingestion_service.dart';

class ExpenseTrackerState extends ChangeNotifier {
  ExpenseTrackerState({StatementIngestionService? ingestionService})
      : _ingestionService = ingestionService ?? StatementIngestionService();

  final StatementIngestionService _ingestionService;
  final List<AccountStatement> _statements = [];

  List<AccountStatement> get statements =>
      List.unmodifiable(_statements);

  List<Transaction> get allTransactions {
    final transactions = _statements
        .expand((statement) => statement.transactions)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  int get statementCount => _statements.length;

  int get transactionCount => allTransactions.length;

  double get totalExpenses => allTransactions
      .where((t) => t.amount < 0)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalIncome => allTransactions
      .where((t) => t.amount > 0)
      .fold(0, (sum, t) => sum + t.amount);

  double get netBalance => totalIncome + totalExpenses;

  AccountStatement ingestJson(
    String jsonString, {
    String? sourceFileName,
  }) {
    final statement = _ingestionService.ingestJson(
      jsonString,
      sourceFileName: sourceFileName,
    );
    _statements.insert(0, statement);
    notifyListeners();
    return statement;
  }

  void removeStatement(String statementId) {
    _statements.removeWhere((statement) => statement.id == statementId);
    notifyListeners();
  }

  void clearAll() {
    _statements.clear();
    notifyListeners();
  }
}
