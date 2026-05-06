part of '../../main_site.dart';

class SyncSection extends StatelessWidget {
  final List<CargoModel> cargos;
  final List<UserModel> carriers;
  final UserModel user;

  const SyncSection({
    super.key,
    required this.cargos,
    required this.carriers,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final recent = cargos.where((cargo) => cargo.createdAt != null).toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    final lastSync = recent.isEmpty ? DateTime.now() : recent.first.createdAt!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final cards = [
              _SyncStatusCard(
                icon: Icons.cloud_done_rounded,
                title: 'Firestore',
                value: 'Online',
                color: const Color(0xFF16A34A),
              ),
              _SyncStatusCard(
                icon: Icons.inventory_2_rounded,
                title: 'Коллекция cargos',
                value: '${cargos.length} записей',
                color: Theme.of(context).colorScheme.primary,
              ),
              _SyncStatusCard(
                icon: Icons.badge_rounded,
                title: 'Коллекция перевозчиков',
                value: '${carriers.length} записей',
                color: const Color(0xFFB45309),
              ),
            ];

            if (compact) {
              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              );
            }

            return Row(
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(
                  icon: Icons.timeline_rounded,
                  title: 'Активность',
                ),
                const SizedBox(height: 16),
                _SyncTimelineRow(
                  icon: Icons.login_rounded,
                  title: user.displayName,
                  subtitle: user.email,
                  time: DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                ),
                _SyncTimelineRow(
                  icon: Icons.cloud_sync_rounded,
                  title: 'Последняя запись',
                  subtitle: recent.isEmpty
                      ? 'Пока нет грузов'
                      : '${recent.first.title}: ${recent.first.from} -> ${recent.first.to}',
                  time: DateFormat('dd.MM.yyyy HH:mm').format(lastSync),
                ),
                _SyncTimelineRow(
                  icon: Icons.rule_rounded,
                  title: 'Общий источник данных',
                  subtitle: 'Firebase project: ${AppFirebaseOptions.projectId}',
                  time: 'Live',
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SyncStatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
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

class _SyncTimelineRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final bool isLast;

  const _SyncTimelineRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colors.primary, size: 18),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 42,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
