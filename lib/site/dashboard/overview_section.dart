part of '../../main_site.dart';

class OverviewSection extends StatelessWidget {
  final SiteWorkspaceConfig workspace;
  final List<CargoModel> cargos;
  final List<CargoModel> allCargos;
  final List<UserModel> carriers;
  final List<UserModel> users;
  final List<CargoApplicationModel> applications;
  final List<TransportModel> transports;
  final UserModel user;
  final VoidCallback? onCreateCargo;
  final VoidCallback? onAddTransport;
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
    required this.allCargos,
    required this.carriers,
    required this.users,
    required this.applications,
    required this.transports,
    required this.user,
    required this.onCreateCargo,
    required this.onAddTransport,
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
        const SizedBox(height: 18),
        _buildRoleStatsGrid(context, stats),
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
                  child: _RoleQuickActionsPanel(
                    user: user,
                    onCreateCargo: onCreateCargo,
                    onAddTransport: onAddTransport,
                    onOpenSection: onOpenSection,
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
          _RoleQuickActionsPanel(
            user: user,
            onCreateCargo: onCreateCargo,
            onAddTransport: onAddTransport,
            onOpenSection: onOpenSection,
            onOpenSettings: onOpenSettings,
          ),
        ],
      ],
    );
  }

  Widget _buildRoleStatsGrid(BuildContext context, CargoStatsView stats) {
    final averagePrice = stats.total == 0 ? 0.0 : stats.revenue / stats.total;
    final openPublicCargos = allCargos
        .where((cargo) =>
            cargo.isPublished ||
            cargo.hasApplications ||
            cargo.status == CargoStatus.executorSelected)
        .where((cargo) => !cargo.isFinished && !cargo.isCancelled)
        .length;
    final withoutCarrier =
        allCargos.where((cargo) => cargo.isActive && !cargo.hasExecutor).length;
    final ownApplications =
        applications.where((item) => item.ownerId == user.uid).length;

    final cards = <Widget>[];
    void addMetric({
      required String title,
      required String value,
      required IconData icon,
      required Color color,
      String? description,
      VoidCallback? onTap,
    }) {
      cards.add(
        AppStatCard(
          title: title,
          value: value,
          icon: icon,
          accentColor: color,
          description: description,
          onTap: onTap,
        ),
      );
    }

    if (user.isAdmin) {
      addMetric(
        title: 'Пользователи',
        value: users.length.toString(),
        icon: Icons.people_alt_rounded,
        color: Theme.of(context).colorScheme.primary,
        onTap: () => onOpenSection(SiteSection.users),
      );
      addMetric(
        title: 'Грузы',
        value: allCargos.length.toString(),
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF0891B2),
        onTap: () => onOpenSection(SiteSection.cargos),
      );
      addMetric(
        title: 'Транспорт',
        value: transports.length.toString(),
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => onOpenSection(SiteSection.findTransport),
      );
      addMetric(
        title: 'Споры',
        value: allCargos.where((cargo) => cargo.isInDispute).length.toString(),
        icon: Icons.gavel_rounded,
        color: const Color(0xFFDC2626),
        onTap: () => onOpenMyCargosWithStatus(CargoStatus.dispute),
      );
    } else if (user.isCarrier && !user.canCreateCargo) {
      addMetric(
        title: 'Доступные грузы',
        value: openPublicCargos.toString(),
        icon: Icons.search_rounded,
        color: Theme.of(context).colorScheme.primary,
        onTap: () => onOpenSection(SiteSection.cargos),
      );
      addMetric(
        title: 'Мои рейсы',
        value: stats.total.toString(),
        icon: Icons.route_rounded,
        color: const Color(0xFF0891B2),
        onTap: onOpenCargo,
      );
      addMetric(
        title: 'В пути',
        value: stats.inTransit.toString(),
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => onOpenMyCargosWithStatus(CargoStatus.inTransit),
      );
      addMetric(
        title: 'Ожидают оплаты',
        value: stats.waitingPayment.toString(),
        icon: Icons.payments_rounded,
        color: const Color(0xFFD97706),
        onTap: () => onOpenMyCargosWithStatus(CargoStatus.waitingPayment),
      );
    } else if (user.isCargoOwner && !user.isLogistician) {
      addMetric(
        title: 'Мои опубликованные грузы',
        value: stats.total.toString(),
        icon: Icons.inventory_2_rounded,
        color: Theme.of(context).colorScheme.primary,
        onTap: onOpenCargo,
      );
      addMetric(
        title: 'Отклики',
        value: ownApplications.toString(),
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () => onOpenSection(SiteSection.applications),
      );
      addMetric(
        title: 'Ждут перевозчика',
        value: withoutCarrier.toString(),
        icon: Icons.person_search_rounded,
        color: const Color(0xFFEAB308),
        onTap: onOpenMyCargosActive,
      );
      addMetric(
        title: 'Закрытые рейсы',
        value: stats.closed.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        onTap: () => onOpenMyCargosWithStatus(CargoStatus.closed),
      );
    } else if (user.isForwarder) {
      addMetric(
        title: 'Доступные заявки',
        value: openPublicCargos.toString(),
        icon: Icons.assignment_rounded,
        color: Theme.of(context).colorScheme.primary,
        onTap: () => onOpenSection(SiteSection.cargos),
      );
      addMetric(
        title: 'В сопровождении',
        value: stats.active.toString(),
        icon: Icons.route_rounded,
        color: const Color(0xFF0891B2),
        onTap: onOpenMyCargosActive,
      );
      addMetric(
        title: 'Фото и документы',
        value:
            cargos.where((cargo) => cargo.photos.isNotEmpty).length.toString(),
        icon: Icons.photo_library_rounded,
        color: const Color(0xFF7C3AED),
        onTap: onOpenCargo,
      );
      addMetric(
        title: 'Спорные заявки',
        value: stats.inDispute.toString(),
        icon: Icons.gavel_rounded,
        color: const Color(0xFFDC2626),
        onTap: () => onOpenMyCargosWithStatus(CargoStatus.dispute),
      );
    } else {
      addMetric(
        title: 'Активные грузы',
        value: stats.active.toString(),
        icon: Icons.inventory_2_rounded,
        color: Theme.of(context).colorScheme.primary,
        onTap: onOpenMyCargosActive,
      );
      addMetric(
        title: 'Без исполнителя',
        value: withoutCarrier.toString(),
        icon: Icons.person_search_rounded,
        color: const Color(0xFFEAB308),
        onTap: onOpenMyCargosActive,
      );
      addMetric(
        title: 'Ожидают погрузки',
        value: stats.waitingLoading.toString(),
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF97316),
        onTap: () => onOpenMyCargosWithStatus(CargoStatus.waitingLoading),
      );
      addMetric(
        title: 'В споре',
        value: stats.inDispute.toString(),
        icon: Icons.gavel_rounded,
        color: const Color(0xFFDC2626),
        onTap: () => onOpenMyCargosWithStatus(CargoStatus.dispute),
      );
    }

    addMetric(
      title: 'Средний чек',
      value: _formatMoney(averagePrice),
      icon: Icons.insights_rounded,
      color: const Color(0xFF7C3AED),
      description: 'По видимым рейсам',
      onTap: onOpenCargo,
    );

    return AppResponsiveGrid(
      desktopCrossAxisCount: 4,
      tabletCrossAxisCount: 2,
      mobileCrossAxisCount: 1,
      children: cards,
    );
  }

  Widget buildStatsGridLegacy(
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

class _RoleQuickActionsPanel extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onCreateCargo;
  final VoidCallback? onAddTransport;
  final ValueChanged<SiteSection> onOpenSection;
  final VoidCallback onOpenSettings;

  const _RoleQuickActionsPanel({
    required this.user,
    required this.onCreateCargo,
    required this.onAddTransport,
    required this.onOpenSection,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    void add({
      required String label,
      required IconData icon,
      required VoidCallback? onPressed,
      AppButtonVariant variant = AppButtonVariant.secondary,
    }) {
      if (onPressed == null) return;
      actions.add(AppButton(
        label: label,
        icon: icon,
        variant: variant,
        onPressed: onPressed,
      ));
    }

    if (user.isAdmin) {
      add(
        label: 'Пользователи',
        icon: Icons.people_alt_rounded,
        onPressed: () => onOpenSection(SiteSection.users),
      );
      add(
        label: 'Грузы',
        icon: Icons.inventory_2_rounded,
        onPressed: () => onOpenSection(SiteSection.cargos),
      );
      add(
        label: 'История',
        icon: Icons.manage_history_rounded,
        onPressed: () => onOpenSection(SiteSection.activity),
      );
    } else if (user.isCarrier && !user.canCreateCargo) {
      add(
        label: 'Найти груз',
        icon: Icons.search_rounded,
        onPressed: () => onOpenSection(SiteSection.cargos),
      );
      add(
        label: 'Добавить транспорт',
        icon: Icons.local_shipping_rounded,
        onPressed: onAddTransport,
      );
      add(
        label: 'Открыть чаты',
        icon: Icons.forum_rounded,
        onPressed: () => onOpenSection(SiteSection.chats),
      );
    } else if (user.isCargoOwner && !user.isLogistician) {
      add(
        label: 'Создать груз',
        icon: Icons.add_rounded,
        onPressed: onCreateCargo,
      );
      add(
        label: 'Отклики',
        icon: Icons.how_to_reg_rounded,
        onPressed: () => onOpenSection(SiteSection.applications),
      );
    } else if (user.isForwarder) {
      add(
        label: 'Найти груз',
        icon: Icons.search_rounded,
        onPressed: () => onOpenSection(SiteSection.cargos),
      );
      add(
        label: 'Открыть чаты',
        icon: Icons.forum_rounded,
        onPressed: () => onOpenSection(SiteSection.chats),
      );
    } else {
      add(
        label: 'Создать груз',
        icon: Icons.add_rounded,
        onPressed: onCreateCargo,
      );
      add(
        label: 'Найти перевозчика',
        icon: Icons.local_shipping_rounded,
        onPressed: () => onOpenSection(SiteSection.findTransport),
      );
      add(
        label: 'Отклики',
        icon: Icons.how_to_reg_rounded,
        onPressed: () => onOpenSection(SiteSection.applications),
      );
    }

    add(
      label: 'Профиль',
      icon: Icons.account_circle_outlined,
      onPressed: onOpenSettings,
      variant: AppButtonVariant.ghost,
    );

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Быстрые действия'),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: actions),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 16),
          _ProfileReadinessSummary(user: user, onOpenSettings: onOpenSettings),
        ],
      ),
    );
  }
}

class _ProfileReadinessSummary extends StatelessWidget {
  final UserModel user;
  final VoidCallback onOpenSettings;

  const _ProfileReadinessSummary({
    required this.user,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percent = user.effectiveProfileCompletenessPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: user.effectiveProfileStatus == 'verified'
              ? 'Профиль подтверждён'
              : 'Статус профиля',
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          minHeight: 7,
          value: percent / 100,
          color: colors.primary,
          backgroundColor: colors.surfaceContainerHighest,
        ),
        const SizedBox(height: 8),
        Text(
          '$percent% заполнено',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (percent < 100) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Заполнить профиль'),
          ),
        ],
      ],
    );
  }
}

class NotificationsPanelLegacy extends StatelessWidget {
  final VoidCallback onOpenCargoSearch;
  final VoidCallback onOpenSettings;

  const NotificationsPanelLegacy({
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
