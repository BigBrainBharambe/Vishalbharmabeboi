import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/expense_tracker_state.dart';
import '../services/statement_ingestion_service.dart';
import 'transactions_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import statement'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Paste or load JSON',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports credit card and bank account statements exported as JSON. '
            'Transactions should be in a "transactions" array with date, description, and amount.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 10,
            maxLines: 18,
            decoration: InputDecoration(
              hintText: '{ "account": { ... }, "transactions": [ ... ] }',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isImporting ? null : () => _loadSample('cc'),
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text('Load CC sample'),
              ),
              OutlinedButton.icon(
                onPressed: _isImporting ? null : () => _loadSample('bank'),
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Load bank sample'),
              ),
              OutlinedButton.icon(
                onPressed: _isImporting ? null : _pickFile,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Pick JSON file'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isImporting ? null : _import,
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isImporting ? 'Importing...' : 'Import statement'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSample(String type) async {
    final assetPath = type == 'cc'
        ? 'assets/samples/sample_cc_statement.json'
        : 'assets/samples/sample_bank_statement.json';

    final json = await rootBundle.loadString(assetPath);
    setState(() {
      _controller.text = json;
      _error = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Could not read the selected file.');
      return;
    }

    setState(() {
      _controller.text = String.fromCharCodes(bytes);
      _error = null;
    });
  }

  Future<void> _import() async {
    final json = _controller.text.trim();
    if (json.isEmpty) {
      setState(() => _error = 'Paste JSON or load a sample first.');
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
    });

    try {
      final statement = context.read<ExpenseTrackerState>().ingestJson(json);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${statement.transactionCount} transactions from ${statement.account.displayName}',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
      );
    } on StatementIngestionException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}
