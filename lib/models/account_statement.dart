import 'account_info.dart';
import 'transaction.dart';

class StatementPeriod {
  const StatementPeriod({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  factory StatementPeriod.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StatementPeriod();

    return StatementPeriod(
      start: _readDate(json['start'] ?? json['from'] ?? json['begin']),
      end: _readDate(json['end'] ?? json['to'] ?? json['until']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (start != null) 'start': start!.toIso8601String(),
        if (end != null) 'end': end!.toIso8601String(),
      };
}

class AccountStatement {
  const AccountStatement({
    required this.id,
    required this.account,
    required this.transactions,
    required this.importedAt,
    this.period,
    this.sourceFileName,
  });

  final String id;
  final AccountInfo account;
  final List<Transaction> transactions;
  final DateTime importedAt;
  final StatementPeriod? period;
  final String? sourceFileName;

  int get transactionCount => transactions.length;

  double get totalExpenses => transactions
      .where((t) => t.amount < 0)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalIncome => transactions
      .where((t) => t.amount > 0)
      .fold(0, (sum, t) => sum + t.amount);

  double get netTotal =>
      transactions.fold(0, (sum, t) => sum + t.amount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'account': account.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'imported_at': importedAt.toIso8601String(),
        if (period != null) 'statement_period': period!.toJson(),
        if (sourceFileName != null) 'source_file_name': sourceFileName,
      };
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is int) {
    final millis = value > 9999999999 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return DateTime.tryParse(value.toString());
}
