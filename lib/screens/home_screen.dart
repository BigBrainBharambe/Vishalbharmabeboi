import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_info.dart';
import '../models/account_statement.dart';
import '../providers/expense_tracker_state.dart';
import 'import_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExpenseTrackerState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          if (state.statementCount > 0)
            IconButton(
              tooltip: 'Clear all data',
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(state: state),
          const SizedBox(height: 20),
          Text(
            'Get started',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.upload_file_outlined,
            title: 'Import statement',
            subtitle: 'Upload a JSON file from your credit card or bank account',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'View transactions',
            subtitle: state.transactionCount == 0
                ? 'Import a statement to see transactions'
                : '${state.transactionCount} transactions across ${state.statementCount} statement(s)',
            onTap: state.transactionCount == 0
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionsScreen(),
                      ),
                    ),
          ),
          if (state.statements.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Imported statements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...state.statements.map(
              (statement) => _StatementCard(statement: statement),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Import'),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This removes all imported statements and transactions from this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ExpenseTrackerState>().clearAll();
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final ExpenseTrackerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Income',
                    value: state.totalIncome,
                    color: Colors.green.shade700,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Expenses',
                    value: state.totalExpenses,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 8),
            _Metric(
              label: 'Net balance',
              value: state.netBalance,
              color: theme.colorScheme.primary,
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final prefix = value >= 0 ? '+' : '';
    final textStyle = emphasize
        ? Theme.of(context).textTheme.headlineSmall
        : Theme.of(context).textTheme.titleLarge;

    return Column(
      crossAxisAlignment:
          emphasize ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix\$${value.abs().toStringAsFixed(2)}',
          style: textStyle?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.statement});

  final AccountStatement statement;

  @override
  Widget build(BuildContext context) {
    final account = statement.account;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            account.type == AccountType.creditCard
                ? Icons.credit_card
                : Icons.account_balance,
          ),
        ),
        title: Text(account.displayName),
        subtitle: Text(
          '${statement.transactionCount} transactions'
          '${statement.sourceFileName != null ? ' • ${statement.sourceFileName}' : ''}',
        ),
        trailing: Text(
          '\$${statement.netTotal.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: statement.netTotal >= 0
                ? Colors.green.shade700
                : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
