import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/expense_tracker_state.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<ExpenseTrackerState>().allTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions yet.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return TransactionTile(transaction: transactions[index]);
              },
            ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().format(transaction.date);
    final amountColor =
        transaction.isExpense ? Colors.red.shade700 : Colors.green.shade700;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withValues(alpha: 0.12),
        child: Icon(
          transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(transaction.description),
      subtitle: Text(
        [
          dateLabel,
          transaction.category,
          transaction.accountName,
        ].whereType<String>().join(' • '),
      ),
      trailing: Text(
        '${transaction.isIncome ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
        style: TextStyle(
          color: amountColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
