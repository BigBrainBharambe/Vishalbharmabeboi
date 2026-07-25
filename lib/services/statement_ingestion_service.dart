import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/account_info.dart';
import '../models/account_statement.dart';
import '../models/transaction.dart';

class StatementIngestionException implements Exception {
  StatementIngestionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StatementIngestionService {
  StatementIngestionService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  AccountStatement ingestJson(
    String jsonString, {
    String? sourceFileName,
  }) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException catch (e) {
      throw StatementIngestionException('Invalid JSON: ${e.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw StatementIngestionException(
        'Expected a JSON object at the root. Got ${decoded.runtimeType}.',
      );
    }

    return _parseStatement(decoded, sourceFileName: sourceFileName);
  }

  AccountStatement _parseStatement(
    Map<String, dynamic> json, {
    String? sourceFileName,
  }) {
    final statementId = _uuid.v4();
    final account = _parseAccount(json);
    final period = StatementPeriod.fromJson(
      _readMap(json, ['statement_period', 'statementPeriod', 'period']),
    );
    final rawTransactions = _extractTransactions(json);

    if (rawTransactions.isEmpty) {
      throw StatementIngestionException(
        'No transactions found. Include a "transactions" array in the JSON.',
      );
    }

    final transactions = <Transaction>[];
    for (var i = 0; i < rawTransactions.length; i++) {
      final item = rawTransactions[i];
      if (item is! Map<String, dynamic>) {
        throw StatementIngestionException(
          'Transaction at index $i must be an object.',
        );
      }

      transactions.add(
        Transaction.fromJson(
          item,
          account: account,
          statementId: statementId,
          id: _uuid.v4(),
        ),
      );
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    return AccountStatement(
      id: statementId,
      account: account,
      transactions: transactions,
      importedAt: DateTime.now(),
      period: period,
      sourceFileName: sourceFileName,
    );
  }

  AccountInfo _parseAccount(Map<String, dynamic> json) {
    final accountJson = _readMap(json, ['account', 'account_info', 'accountInfo']);
    if (accountJson != null) {
      return AccountInfo.fromJson(accountJson);
    }

    return AccountInfo(
      name: _readString(json, ['account_name', 'accountName', 'name']) ??
          'Imported Account',
      type: AccountType.fromString(
        _readString(json, ['account_type', 'accountType', 'type']),
      ),
      institution: _readString(json, ['institution', 'bank', 'issuer']),
      lastFour: _readString(json, ['last_four', 'lastFour', 'last4']),
    );
  }

  List<dynamic> _extractTransactions(Map<String, dynamic> json) {
    final direct = json['transactions'] ??
        json['entries'] ??
        json['items'] ??
        json['records'];

    if (direct is List) return direct;

    final nested = _readMap(json, ['statement', 'data']);
    if (nested != null) {
      final nestedTransactions = nested['transactions'] ??
          nested['entries'] ??
          nested['items'] ??
          nested['records'];
      if (nestedTransactions is List) return nestedTransactions;
    }

    return const [];
  }

  Map<String, dynamic>? _readMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }
}
