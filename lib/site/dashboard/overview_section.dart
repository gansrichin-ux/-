part of '../../main_site.dart';

class OverviewSection extends StatelessWidget {
  final List<CargoModel> cargos;
  final List<UserModel> drivers;
  final UserModel user;
  final VoidCallback onOpenCargo;

  const OverviewSection({
    super.key,
    required this.cargos,
    required this.drivers,
    required this.user,
    required this.onOpenCargo,
  });

  @override
  Widget build(BuildContext context) {
    final stats = CargoStatsView(cargos);
    final recent = cargos.take(5).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        _MarketplaceHomePanel(
          onOpenCargo: onOpenCargo,
        ),
        const SizedBox(height: 18),
        _HeroStrip(stats: stats, user: user, onOpenCargo: onOpenCargo),
        const SizedBox(height: 18),
        _StatsGrid(stats: stats, driverCount: drivers.length),
        const SizedBox(height: 18),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: _WorkloadPanel(stats: stats)),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: _RecentCargoPanel(cargos: recent)),
              ],
            ),
          )
        else ...[
          _WorkloadPanel(stats: stats),
          const SizedBox(height: 18),
          _RecentCargoPanel(cargos: recent),
        ],
      ],
    );
  }
}

class _MarketplaceHomePanel extends StatelessWidget {
  final VoidCallback onOpenCargo;

  const _MarketplaceHomePanel({
    required this.onOpenCargo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final brand = Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGIST.APP',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Грузоперевозки, заявки и исполнители в одной системе',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final search = TextField(
                  decoration: const InputDecoration(
                    hintText: 'Например: Алматы -> Астана, тент, 20 т',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => onOpenCargo(),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [brand, const SizedBox(height: 14), search],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 5, child: brand),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: search),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Сервис помогает логистам создавать заявки, назначать водителей, обсуждать детали груза в чате и оценивать участников после работы. Все данные синхронизируются с мобильным приложением через Firebase.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStrip extends StatelessWidget {
  final CargoStatsView stats;
  final UserModel user;
  final VoidCallback onOpenCargo;

  const _HeroStrip({
    required this.stats,
    required this.user,
    required this.onOpenCargo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final completion = stats.total == 0 ? 0.0 : stats.completed / stats.total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final content = [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добро пожаловать, ${user.displayName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Сегодня в работе ${stats.active} активных рейсов',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InlineMetric(
                        icon: Icons.payments_rounded,
                        label: _formatMoney(stats.revenue),
                      ),
                      _InlineMetric(
                        icon: Icons.route_rounded,
                        label: '${stats.distance.toStringAsFixed(0)} км',
                      ),
                      _InlineMetric(
                        icon: Icons.inventory_2_rounded,
                        label: '${stats.unassigned} без водителя',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20, height: 18),
            SizedBox(
              width: compact ? double.infinity : 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${(completion * 100).round()}%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: colors.secondary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: completion,
                      backgroundColor: colors.secondary.withOpacity(0.14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onOpenCargo,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Открыть грузы'),
                  ),
                ],
              ),
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            );
          }

          return Row(children: content);
        },
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final CargoStatsView stats;
  final int driverCount;

  const _StatsGrid({required this.stats, required this.driverCount});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        title: 'Всего грузов',
        value: stats.total.toString(),
        icon: Icons.inventory_2_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      _StatCard(
        title: 'В пути',
        value: stats.inTransit.toString(),
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF0891B2),
      ),
      _StatCard(
        title: 'Доставлено',
        value: stats.completed.toString(),
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF16A34A),
      ),
      _StatCard(
        title: 'Водители',
        value: driverCount.toString(),
        icon: Icons.badge_rounded,
        color: const Color(0xFFB45309),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 720
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 3.3 : 2.25,
          children: cards,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
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

class _WorkloadPanel extends StatelessWidget {
  final CargoStatsView stats;

  const _WorkloadPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      stats.newCount,
      stats.inTransit,
      stats.completed,
      stats.cancelled,
    ].fold<int>(1, (max, value) => value > max ? value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              icon: Icons.query_stats_rounded,
              title: 'Рабочая нагрузка',
              trailing: _StatusPill(
                label: stats.unassigned > 0
                    ? '${stats.unassigned} без водителя'
                    : 'Назначения закрыты',
                color: stats.unassigned > 0
                    ? const Color(0xFFB45309)
                    : const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 18),
            _BarRow(
              label: 'Новые',
              value: stats.newCount,
              maxValue: maxValue,
              color: const Color(0xFF2563EB),
            ),
            _BarRow(
              label: 'В пути',
              value: stats.inTransit,
              maxValue: maxValue,
              color: const Color(0xFF0891B2),
            ),
            _BarRow(
              label: 'Доставлено',
              value: stats.completed,
              maxValue: maxValue,
              color: const Color(0xFF16A34A),
            ),
            _BarRow(
              label: 'Отменено',
              value: stats.cancelled,
              maxValue: maxValue,
              color: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            _RouteQuality(stats: stats),
          ],
        ),
      ),
    );
  }
}

class _RouteQuality extends StatelessWidget {
  final CargoStatsView stats;

  const _RouteQuality({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final averagePrice = stats.total == 0 ? 0.0 : stats.revenue / stats.total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.tertiary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.tertiary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: colors.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Средний чек рейса: ${_formatMoney(averagePrice)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final widthFactor = value / maxValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: widthFactor,
                color: color,
                backgroundColor: color.withOpacity(0.12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 34,
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCargoPanel extends StatelessWidget {
  final List<CargoModel> cargos;

  const _RecentCargoPanel({required this.cargos});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelHeader(
              icon: Icons.history_rounded,
              title: 'Последние грузы',
            ),
            const SizedBox(height: 12),
            if (cargos.isEmpty)
              const SizedBox(
                height: 220,
                child: Center(
                  child: _StatePanel(
                    icon: Icons.inventory_2_outlined,
                    title: 'Нет грузов',
                    message: 'Создайте первую заявку.',
                  ),
                ),
              )
            else
              ...cargos.map(
                (cargo) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompactCargoRow(cargo: cargo),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactCargoRow extends StatelessWidget {
  final CargoModel cargo;

  const _CompactCargoRow({required this.cargo});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(cargo.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cargo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${cargo.from} -> ${cargo.to}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(label: cargo.status, color: color),
        ],
      ),
    );
  }
}
