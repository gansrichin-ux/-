part of '../../main_site.dart';

class OverviewSection extends StatelessWidget {
  final SiteWorkspaceConfig workspace;
  final List<CargoModel> cargos;
  final List<UserModel> carriers;
  final UserModel user;
  final VoidCallback? onCreateCargo;
  final VoidCallback onOpenCargo;
  final ValueChanged<CargoModel> onOpenRecentCargo;
  final ValueChanged<SiteSection> onOpenSection;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onOpenMyCargosWithStatus;
  final VoidCallback onOpenMyCargosActive;

  const OverviewSection({
    super.key,
    required this.workspace,
    required this.cargos,
    required this.carriers,
    required this.user,
    required this.onCreateCargo,
    required this.onOpenCargo,
    required this.onOpenRecentCargo,
    required this.onOpenSection,
    required this.onOpenSettings,
    required this.onOpenMyCargosWithStatus,
    required this.onOpenMyCargosActive,
  });

  @override
  Widget build(BuildContext context) {
    final stats = CargoStatsView(cargos);
    final recent = cargos.take(5).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        AppPageHeader(
          title: workspace.title,
          subtitle:
              '${workspace.subtitle}\n${user.displayUsername} · ${user.displayRole}',
          trailing: onCreateCargo == null
              ? null
              : AppButton(
                  label: 'Добавить груз',
                  icon: Icons.add_rounded,
                  onPressed: onCreateCargo,
                ),
        ),
        const SizedBox(height: 8),
        _RoleWorkspaceHero(
          workspace: workspace,
          user: user,
          onOpenSection: onOpenSection,
        ),
        const SizedBox(height: 24),
        _buildStatsGrid(context, stats, carriers.length),
        const SizedBox(height: 24),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    flex: 7,
                    child: _RecentActionsPanel(
                      cargos: recent,
                      onOpenCargo: onOpenCargo,
                      onOpenRecentCargo: onOpenRecentCargo,
                    )),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: _NotificationsPanel(
                    onOpenCargoSearch: () => onOpenSection(SiteSection.cargos),
                    onOpenSettings: onOpenSettings,
                  ),
                ),
              ],
            ),
          )
        else ...[
          _RecentActionsPanel(
            cargos: recent,
            onOpenCargo: onOpenCargo,
            onOpenRecentCargo: onOpenRecentCargo,
          ),
          const SizedBox(height: 24),
          _NotificationsPanel(
            onOpenCargoSearch: () => onOpenSection(SiteSection.cargos),
            onOpenSettings: onOpenSettings,
          ),
        ],
      ],
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, CargoStatsView stats, int carrierCount) {
    final averagePrice = stats.total == 0 ? 0.0 : stats.revenue / stats.total;

    return AppResponsiveGrid(
      desktopCrossAxisCount: 4,
      tabletCrossAxisCount: 2,
      mobileCrossAxisCount: 1,
      children: [
        AppStatCard(
          title: 'Активные грузы',
          value: stats.active.toString(),
          icon: Icons.inventory_2_rounded,
          accentColor: Theme.of(context).colorScheme.primary,
          onTap: onOpenMyCargosActive,
        ),
        AppStatCard(
          title: 'В пути',
          value: stats.inTransit.toString(),
          icon: Icons.local_shipping_rounded,
          accentColor: const Color(0xFF0891B2),
          onTap: () => onOpenMyCargosWithStatus(CargoStatus.inTransit),
        ),
        AppStatCard(
          title: 'Ожидают подтверждения',
          value: stats.waitingConfirmation.toString(),
          icon: Icons.fact_check_rounded,
          accentColor: const Color(0xFFEAB308),
          onTap: () =>
              onOpenMyCargosWithStatus(CargoStatus.waitingConfirmation),
        ),
        AppStatCard(
          title: 'Ожидают погрузки',
          value: stats.waitingLoading.toString(),
          icon: Icons.hourglass_top_rounded,
          accentColor: const Color(0xFFF97316),
          onTap: () => onOpenMyCargosWithStatus(CargoStatus.waitingLoading),
        ),
        AppStatCard(
          title: 'Ожидают оплаты',
          value: stats.waitingPayment.toString(),
          icon: Icons.payments_rounded,
          accentColor: const Color(0xFFD97706),
          onTap: () => onOpenMyCargosWithStatus(CargoStatus.waitingPayment),
        ),
        AppStatCard(
          title: 'В споре',
          value: stats.inDispute.toString(),
          icon: Icons.gavel_rounded,
          accentColor: const Color(0xFFDC2626),
          onTap: () => onOpenMyCargosWithStatus(CargoStatus.dispute),
        ),
        AppStatCard(
          title: 'Средний чек',
          value: _formatMoney(averagePrice),
          icon: Icons.insights_rounded,
          accentColor: const Color(0xFF7C3AED),
          description: 'По всем рейсам',
          onTap: onOpenCargo,
        ),
        AppStatCard(
          title: 'Закрытые рейсы',
          value: stats.closed.toString(),
          icon: Icons.check_circle_rounded,
          accentColor: const Color(0xFF16A34A),
          onTap: () => onOpenMyCargosWithStatus(CargoStatus.closed),
        ),
      ],
    );
  }
}

class _RecentActionsPanel extends StatelessWidget {
  final List<CargoModel> cargos;
  final VoidCallback onOpenCargo;
  final ValueChanged<CargoModel> onOpenRecentCargo;

  const _RecentActionsPanel({
    required this.cargos,
    required this.onOpenCargo,
    required this.onOpenRecentCargo,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Последние действия',
            trailing: TextButton(
              onPressed: onOpenCargo,
              child: const Text('Все грузы'),
            ),
          ),
          if (cargos.isEmpty)
            const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'Нет недавних действий',
              message:
                  'Здесь будет отображаться история изменения ваших грузов.',
            )
          else
            AppResponsiveList(
              children: cargos
                  .map(
                    (c) => _RecentActionItem(
                      cargo: c,
                      onTap: () => onOpenRecentCargo(c),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RecentActionItem extends StatelessWidget {
  final CargoModel cargo;
  final VoidCallback onTap;

  const _RecentActionItem({required this.cargo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_document,
                  size: 20, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Груз: ${cargo.title}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Статус изменен на "${CargoStatus.getDisplayStatus(cargo.status)}"',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CargoStatusBadge(status: cargo.status),
          ],
        ),
      ),
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  final VoidCallback onOpenCargoSearch;
  final VoidCallback onOpenSettings;

  const _NotificationsPanel({
    required this.onOpenCargoSearch,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Последние уведомления'),
          const AppEmptyState(
            icon: Icons.notifications_off_rounded,
            title: 'Нет новых уведомлений',
            message: 'Мы сообщим вам, когда появится что-то важное.',
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'Быстрые действия'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(
                label: 'Поиск груза',
                icon: Icons.search_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: onOpenCargoSearch,
              ),
              AppButton(
                label: 'Настройки',
                icon: Icons.settings_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: onOpenSettings,
              ),
            ],
          )
        ],
      ),
    );
  }
}
