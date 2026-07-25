import 'account_info.dart';

enum TransactionType {
  debit,
  credit,
  unknown;

  static TransactionType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'debit':
      case 'expense':
      case 'withdrawal':
      case 'purchase':
        return TransactionType.debit;
      case 'credit':
      case 'income':
      case 'deposit':
      case 'payment':
        return TransactionType.credit;
      default:
        return TransactionType.unknown;
    }
  }
}

class Transaction {
  const Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.accountName,
    required this.accountType,
    this.category,
    this.merchant,
    this.type = TransactionType.unknown,
    this.statementId,
    this.raw,
  });

  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String accountName;
  final AccountType accountType;
  final String? category;
  final String? merchant;
  final TransactionType type;
  final String? statementId;
  final Map<String, dynamic>? raw;

  bool get isExpense => amount < 0;

  bool get isIncome => amount > 0;

  String get signedAmountLabel {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${amount.toStringAsFixed(2)}';
  }

  Transaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? amount,
    String? accountName,
    AccountType? accountType,
    String? category,
    String? merchant,
    TransactionType? type,
    String? statementId,
    Map<String, dynamic>? raw,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      type: type ?? this.type,
      statementId: statementId ?? this.statementId,
      raw: raw ?? this.raw,
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    required AccountInfo account,
    required String statementId,
    required String id,
  }) {
    final amount = _readAmount(json);
    final explicitType = TransactionType.fromString(
      _readString(json, ['type', 'transaction_type', 'transactionType']),
    );
    final resolvedType = explicitType == TransactionType.unknown
        ? (amount < 0 ? TransactionType.debit : TransactionType.credit)
        : explicitType;

    return Transaction(
      id: id,
      date: _readDate(json) ?? DateTime.now(),
      description: _readString(json, [
            'description',
            'desc',
            'narration',
            'memo',
            'details',
            'payee',
          ]) ??
          'Unknown transaction',
      amount: amount,
      accountName: account.name,
      accountType: account.type,
      category: _readString(json, ['category', 'cat', 'classification']),
      merchant: _readString(json, ['merchant', 'vendor', 'payee']),
      type: resolvedType,
      statementId: statementId,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'description': description,
        'amount': amount,
        'account_name': accountName,
        'account_type': accountType.name,
        if (category != null) 'category': category,
        if (merchant != null) 'merchant': merchant,
        'type': type.name,
        if (statementId != null) 'statement_id': statementId,
      };
}

double _readAmount(Map<String, dynamic> json) {
  final value = json['amount'] ??
      json['value'] ??
      json['transaction_amount'] ??
      json['transactionAmount'];

  if (value is num) return value.toDouble();

  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  final debit = json['debit'] ?? json['withdrawal'];
  final credit = json['credit'] ?? json['deposit'];

  if (debit != null) {
    final parsed = debit is num ? debit.toDouble() : double.tryParse('$debit');
    if (parsed != null) return -parsed.abs();
  }

  if (credit != null) {
    final parsed =
        credit is num ? credit.toDouble() : double.tryParse('$credit');
    if (parsed != null) return parsed.abs();
  }

  return 0;
}

DateTime? _readDate(Map<String, dynamic> json) {
  final value = json['date'] ??
      json['transaction_date'] ??
      json['transactionDate'] ??
      json['posted_date'] ??
      json['postedDate'] ??
      json['timestamp'];

  if (value == null) return null;

  if (value is int) {
    final millis = value > 9999999999 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  return DateTime.tryParse(value.toString());
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