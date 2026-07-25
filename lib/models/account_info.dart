enum AccountType {
  creditCard,
  bankAccount,
  unknown;

  static AccountType fromString(String? value) {
    switch (value?.toLowerCase().replaceAll(' ', '_')) {
      case 'credit_card':
      case 'creditcard':
      case 'cc':
        return AccountType.creditCard;
      case 'bank_account':
      case 'bankaccount':
      case 'checking':
      case 'savings':
        return AccountType.bankAccount;
      default:
        return AccountType.unknown;
    }
  }

  String get label {
    switch (this) {
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.bankAccount:
        return 'Bank Account';
      case AccountType.unknown:
        return 'Account';
    }
  }
}

class AccountInfo {
  const AccountInfo({
    required this.name,
    required this.type,
    this.institution,
    this.lastFour,
  });

  final String name;
  final AccountType type;
  final String? institution;
  final String? lastFour;

  String get displayName {
    final suffix = lastFour != null ? ' •••• $lastFour' : '';
    return '$name$suffix';
  }

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      name: _readString(json, ['name', 'account_name', 'accountName']) ??
          'Unknown Account',
      type: AccountType.fromString(
        _readString(json, ['type', 'account_type', 'accountType']),
      ),
      institution:
          _readString(json, ['institution', 'bank', 'issuer', 'provider']),
      lastFour: _readString(json, ['last_four', 'lastFour', 'last4', 'mask']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type == AccountType.creditCard ? 'credit_card' : 'bank_account',
        if (institution != null) 'institution': institution,
        if (lastFour != null) 'last_four': lastFour,
      };
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value.toString();
  }
  return null;
}
