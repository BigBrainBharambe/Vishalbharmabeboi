# Expense Tracker

A Flutter app that ingests JSON statements from credit cards and bank accounts, then surfaces transactions and spending summaries. This branch is the foundation — more features (categories, budgets, charts, persistence, etc.) can be built on top.

## JSON statement format

The ingestion layer accepts flexible JSON. At minimum, include a `transactions` array with `date`, `description`, and `amount` (negative for expenses, positive for income/credits).

```json
{
  "account": {
    "name": "Chase Sapphire",
    "type": "credit_card",
    "institution": "Chase",
    "last_four": "4821"
  },
  "statement_period": {
    "start": "2026-05-01",
    "end": "2026-05-31"
  },
  "transactions": [
    {
      "date": "2026-05-02",
      "description": "WHOLE FOODS MARKET",
      "amount": -87.43,
      "category": "Groceries",
      "type": "debit"
    }
  ]
}
```

### Supported aliases

| Canonical | Also accepted |
|-----------|----------------|
| `transactions` | `entries`, `items`, `records` |
| `description` | `desc`, `memo`, `narration`, `payee` |
| `date` | `transaction_date`, `posted_date` |
| `amount` | `debit` / `credit` columns |
| `account` object | top-level `account_name`, `account_type` |

Sample files live in `assets/samples/`.

## Project structure

```
lib/
  models/           # Account, transaction, statement models
  services/         # JSON ingestion and parsing
  providers/        # App state (Provider)
  screens/          # Home, import, transactions UI
```

## Getting started

```bash
flutter pub get
flutter run
```

### Run tests

```bash
flutter test
```

## Current features

- Import JSON via paste, file picker, or bundled samples
- Parse CC and bank account statements with flexible field names
- View all transactions sorted by date
- Home overview with income, expenses, and net balance
- Track multiple imported statements in one session

## Build an `.ipa` with Codemagic

This repo includes `codemagic.yaml` for cloud iOS builds.

- **Bundle ID:** `com.vishalbharambe.expensetracker`
- **Workflows:** `ios-unsigned` → `ios-ipa` (signed `.ipa`)

Full Apple Developer + signing steps: see **[CODEMAGIC.md](CODEMAGIC.md)**.

## Planned extensions

- Local persistence (SQLite / Hive)
- Category rules and auto-tagging
- Monthly budgets and alerts
- Charts and spending breakdowns
- CSV / PDF export adapters
- Multi-currency support

## Branch

`cursor/expense-tracker-a654`
