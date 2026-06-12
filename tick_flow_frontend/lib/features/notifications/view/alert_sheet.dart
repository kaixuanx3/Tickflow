import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formats.dart';
import '../../../data/api/api_client.dart';
import '../../../data/alerts/alert_models.dart';
import '../viewmodel/alerts_controller.dart';

Future<void> showAlertSheet(BuildContext context, {Alert? existing, String? symbol}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _AlertSheet(existing: existing, presetSymbol: symbol),
    ),
  );
}

class _AlertSheet extends ConsumerStatefulWidget {
  const _AlertSheet({this.existing, this.presetSymbol});

  final Alert? existing;
  final String? presetSymbol;

  @override
  ConsumerState<_AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends ConsumerState<_AlertSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _symbol;
  late final TextEditingController _threshold;
  late AlertRuleType _ruleType;
  late AlertKind _kind;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _symbol = TextEditingController(text: e?.symbol ?? widget.presetSymbol ?? '');
    _threshold = TextEditingController(text: e == null ? '' : e.threshold.toString());
    _ruleType = e?.ruleType ?? AlertRuleType.priceAbove;
    _kind = e?.kind ?? AlertKind.oneShot;
  }

  @override
  void dispose() {
    _symbol.dispose();
    _threshold.dispose();
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
    final threshold = double.parse(_threshold.text.trim());
    final controller = ref.read(alertsProvider.notifier);
    await _run(() => _isEdit
        ? controller.updateAlert(widget.existing!.id, threshold: threshold, kind: _kind)
        : controller.createAlert(
            symbol: _symbol.text.trim().toUpperCase(),
            ruleType: _ruleType,
            threshold: threshold,
            kind: _kind,
          ));
  }

  Future<void> _delete() async {
    final alert = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${alert.symbol} alert?'),
        content: Text(
          '${alert.ruleType.label} ${formatMoney(alert.threshold)} — this also removes it from your history of active alerts.',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => ref.read(alertsProvider.notifier).removeAlert(alert.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Edit ${widget.existing!.symbol} alert' : 'New price alert',
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
                const SizedBox(height: 16),
                SegmentedButton<AlertRuleType>(
                  segments: [
                    for (final r in AlertRuleType.values)
                      ButtonSegment(value: r, label: Text('Price ${r.label.toLowerCase()}')),
                  ],
                  selected: {_ruleType},
                  showSelectedIcon: false,
                  onSelectionChanged:
                      _busy ? null : (s) => setState(() => _ruleType = s.first),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  'Triggers when the price goes ${widget.existing!.ruleType.label.toLowerCase()} the threshold.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _threshold,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Threshold',
                  prefixText: r'$ ',
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return n == null || n <= 0 ? 'Must be more than 0' : null;
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<AlertKind>(
                segments: [
                  for (final k in AlertKind.values)
                    ButtonSegment(value: k, label: Text(k.label)),
                ],
                selected: {_kind},
                showSelectedIcon: false,
                onSelectionChanged: _busy ? null : (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                _kind == AlertKind.oneShot
                    ? 'Fires once, then stays in your history until re-armed.'
                    : 'Fires, cools down, and automatically re-arms when the price retreats.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                    : Text(_isEdit ? 'Save changes' : 'Create alert'),
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
                    label: const Text('Delete alert'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
