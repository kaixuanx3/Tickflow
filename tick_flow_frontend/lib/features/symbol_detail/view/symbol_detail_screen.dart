import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../data/markets/market_models.dart';
import '../../../core/widgets/star_button.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/markets/symbol_subscriptions.dart';
import '../../../l10n/app_localizations.dart';
import 'candle_chart.dart';

class SymbolDetailScreen extends ConsumerStatefulWidget {
  const SymbolDetailScreen({super.key, required this.symbol});

  final String symbol;

  @override
  ConsumerState<SymbolDetailScreen> createState() => _SymbolDetailScreenState();
}

class _SymbolDetailScreenState extends ConsumerState<SymbolDetailScreen> {
  CandleRange _range = CandleRange.m1;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(quotesProvider.notifier).request(widget.symbol);
      ref.read(symbolSubscriptionsProvider.notifier).retain(widget.symbol);
      _subscribed = true;
    });
  }

  @override
  void dispose() {
    if (_subscribed) {
      ref.read(symbolSubscriptionsProvider.notifier).release(widget.symbol);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider(widget.symbol));
    final quote = ref.watch(quotesProvider.select((m) => m[widget.symbol]));
    final candlesKey = (symbol: widget.symbol, range: _range);
    final candles = ref.watch(candlesProvider(candlesKey));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        actions: [StarButton(symbol: widget.symbol)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profile.when(
            data: (p) => _ProfileHeader(profile: p),
            loading: () => const SizedBox(height: 48),
            error: (_, _) => Text(widget.symbol, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 12),
          _PriceBlock(quote: quote),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<CandleRange>(
                    segments: [
                      for (final r in CandleRange.values)
                        ButtonSegment(value: r, label: Text(r.api)),
                    ],
                    selected: {_range},
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    onSelectionChanged: (s) => setState(() => _range = s.first),
                  ),
                  if (_range == CandleRange.d1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.detailDailyBarsNote,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: candles.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorRetry(
                        message: '$e',
                        onRetry: () => ref.invalidate(candlesProvider(candlesKey)),
                      ),
                      data: (series) => series.candles.isEmpty
                          ? Center(
                              child: Text(
                                l10n.detailNoChartData,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (series.stale)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      l10n.detailCachedChart,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                Expanded(child: CandleChart(candles: series.candles)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _TodayStats(quote: quote),
          const SizedBox(height: 16),
          profile.when(
            data: (p) => _AboutCard(profile: p),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final CompanyProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (profile.exchange?.isNotEmpty ?? false) profile.exchange!,
      if (profile.industry?.isNotEmpty ?? false) profile.industry!,
    ].join(' · ');

    final fallbackLogo = CircleAvatar(
      radius: 20,
      child: Text(profile.symbol.characters.first),
    );

    return Row(
      children: [
        if (profile.logo?.isNotEmpty ?? false)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              profile.logo!,
              width: 40,
              height: 40,
              errorBuilder: (_, _, _) => fallbackLogo,
            ),
          )
        else
          fallbackLogo,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: theme.textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.quote});

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final q = quote;
    if (q == null) {
      return Text(
        '—',
        style: theme.textTheme.headlineMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final market = theme.extension<MarketColors>()!;
    final color = q.changePercent >= 0 ? market.gain : market.loss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              formatMoney(q.price),
              style: tabularDigits(theme.textTheme.headlineMedium!)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (q.delayed) _Badge(l10n.detailDelayed),
            if (q.stale) ...[const SizedBox(width: 4), _Badge(l10n.detailCached)],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.detailChangeToday(
            '${q.change >= 0 ? '+' : ''}${q.change.toStringAsFixed(2)}',
            formatPercent(q.changePercent),
          ),
          style: tabularDigits(theme.textTheme.bodyMedium!).copyWith(color: color),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  const _TodayStats({required this.quote});

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final q = quote;

    Widget stat(String label, double? value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(formatMoney(value), style: tabularDigits(theme.textTheme.bodyLarge!)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.detailTodayTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                stat(l10n.detailStatOpen, q?.open),
                stat(l10n.detailStatHigh, q?.high),
                stat(l10n.detailStatLow, q?.low),
                stat(l10n.detailStatPrevClose, q?.prevClose),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.profile});

  final CompanyProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final rows = <(String, String)>[
      if (profile.industry?.isNotEmpty ?? false) (l10n.detailIndustry, profile.industry!),
      if (profile.exchange?.isNotEmpty ?? false) (l10n.detailExchange, profile.exchange!),
      if (profile.country?.isNotEmpty ?? false) (l10n.detailCountry, profile.country!),
      if (profile.marketCapMillions != null)
        (l10n.detailMarketCap, formatMarketCapMillions(profile.marketCapMillions)),
      if (profile.ipo?.isNotEmpty ?? false) (l10n.detailIpo, profile.ipo!),
      if (profile.website?.isNotEmpty ?? false) (l10n.detailWebsite, profile.website!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.detailAbout, style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: Text(value, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
