import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_retry.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/symbol_search_controller.dart';
import 'symbol_row.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // keeps the clear button and idle hint in sync
    ref.read(symbolSearchProvider.notifier).onQueryChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(symbolSearchProvider);
    final query = _controller.text.trim();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.commonClear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  ),
          ),
          onChanged: _onChanged,
        ),
      ),
      body: query.isEmpty
          ? _CenteredHint(
              icon: Icons.search,
              message: l10n.searchIdle,
            )
          : results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                message: '$e',
                onRetry: () => ref.read(symbolSearchProvider.notifier).retry(),
              ),
              data: (list) => list.isEmpty
                  ? _CenteredHint(
                      icon: Icons.search_off,
                      message: l10n.searchNoMatches(query),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) => SymbolRow(
                        info: list[i],
                        onTap: () => context.push('/symbol/${list[i].symbol}'),
                      ),
                    ),
            ),
    );
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
