import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/api_client.dart';
import '../../../data/portfolio/portfolio_models.dart';
import '../viewmodel/portfolio_controller.dart';

Future<void> showHoldingSheet(BuildContext context, {HoldingValuation? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _HoldingSheet(existing: existing),
    ),
  );
}

class _HoldingSheet extends ConsumerStatefulWidget {
  const _HoldingSheet({this.existing});

  final HoldingValuation? existing;

  @override
  ConsumerState<_HoldingSheet> createState() => _HoldingSheetState();
}

class _HoldingSheetState extends ConsumerState<_HoldingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _symbol;
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late AssetType _type;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _symbol = TextEditingController(text: e?.symbol ?? '');
    _qty = TextEditingController(text: e == null ? '' : _plainNumber(e.qty));
    _price = TextEditingController(text: e == null ? '' : _plainNumber(e.buyPrice));
    _type = e?.assetType ?? AssetType.stock;
  }

  static String _plainNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _symbol.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong — please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.parse(_qty.text.trim());
    final price = double.parse(_price.text.trim());
    final controller = ref.read(portfolioProvider.notifier);
    await _run(() => _isEdit
        ? controller.updateHolding(widget.existing!.id,
            qty: qty, buyPrice: price, assetType: _type)
        : controller.addHolding(
            symbol: _symbol.text.trim().toUpperCase(),
            qty: qty,
            buyPrice: price,
            assetType: _type,
          ));
  }

  Future<void> _delete() async {
    final symbol = widget.existing!.symbol;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove $symbol?'),
        content: const Text('This deletes the holding from your portfolio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref.read(portfolioProvider.notifier).removeHolding(widget.existing!.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Edit ${widget.existing!.symbol}' : 'Add holding',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!_isEdit) ...[
                TextFormField(
                  controller: _symbol,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    helperText: 'US ticker, e.g. AAPL',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter a symbol' : null,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qty,
                      enabled: !_busy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return n == null || n <= 0 ? 'Must be more than 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      enabled: !_busy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Buy price',
                        prefixText: r'$ ',
                      ),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return n == null || n < 0 ? 'Must be 0 or more' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<AssetType>(
                segments: [
                  for (final t in AssetType.values)
                    ButtonSegment(value: t, label: Text(t.label)),
                ],
                selected: {_type},
                showSelectedIcon: false,
                onSelectionChanged:
                    _busy ? null : (s) => setState(() => _type = s.first),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Add holding'),
              ),
              if (_isEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete holding'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
