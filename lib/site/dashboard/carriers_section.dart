part of '../../main_site.dart';

class CarriersSection extends StatelessWidget {
  final List<CargoModel> cargos;
  final List<UserModel> carriers;
  final UserModel user;
  final Future<void> Function(CargoModel cargo, UserModel carrier)
  onAssignCarrier;

  const CarriersSection({
    super.key,
    required this.cargos,
    required this.carriers,
    required this.user,
    required this.onAssignCarrier,
  });

  @override
  Widget build(BuildContext context) {
    if (user.isCarrier) {
      return const Center(
        child: _StatePanel(
          icon: Icons.badge_outlined,
          title: 'Личный кабинет перевозчика',
          message: 'Раздел перевозчиков доступен логисту.',
        ),
      );
    }

    if (carriers.isEmpty) {
      return const Center(
        child: _StatePanel(
          icon: Icons.badge_outlined,
          title: 'Перевозчики не найдены',
          message: 'Список появится после регистрации перевозчиков.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      itemCount: carriers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final carrier = carriers[index];
        final assigned = cargos.where((cargo) => cargo.carrierId == carrier.uid);
        final active = assigned
            .where((cargo) => cargo.status == CargoStatus.inTransit)
            .length;
        final available = cargos
            .where((cargo) => cargo.status == CargoStatus.published && cargo.carrierId == null)
            .toList();

        return AppCard(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final main = Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            carrier.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            carrier.car ?? 'Бригада / транспорт не указаны',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final controls = Row(
                  mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    _CarrierCounter(label: 'Активно', value: active),
                    const SizedBox(width: 10),
                    _CarrierCounter(label: 'Всего', value: assigned.length),
                    const SizedBox(width: 10),
                    if (available.isNotEmpty)
                      AppButton(
                        onPressed: () =>
                            _showAssignDialog(context, carrier, available),
                        icon: Icons.assignment_rounded,
                        label: 'Груз',
                      ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [main, const SizedBox(height: 14), controls],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: main),
                    controls,
                  ],
                );
              },
            ),
        );
      },
    );
  }

  Future<void> _showAssignDialog(
    BuildContext context,
    UserModel carrier,
    List<CargoModel> available,
  ) async {
    final cargo = await showDialog<CargoModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Груз для ${carrier.displayName}'),
        children: available
            .map(
              (cargo) => ListTile(
                leading: const Icon(Icons.inventory_2_rounded),
                title: Text(cargo.title),
                subtitle: Text('${cargo.from} -> ${cargo.to}'),
                onTap: () => Navigator.pop(context, cargo),
              ),
            )
            .toList(),
      ),
    );

    if (cargo != null) await onAssignCarrier(cargo, carrier);
  }
}

class _CarrierCounter extends StatelessWidget {
  final String label;
  final int value;

  const _CarrierCounter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
