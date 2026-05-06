part of '../../main_site.dart';

class ApplicationsSection extends StatelessWidget {
  final UserModel user;
  final List<CargoModel> cargos;
  final List<CargoApplicationModel> applications;
  final Future<void> Function(
    CargoApplicationModel application,
    CargoModel cargo,
    bool accepted,
  ) onDecision;

  const ApplicationsSection({
    super.key,
    required this.user,
    required this.cargos,
    required this.applications,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    final visible = applications.where((a) {
      final isMyApplication = a.applicantId == user.uid;
      final isMyCargo = cargos.any((c) => c.id == a.cargoId && c.ownerId == user.uid);
      return isMyApplication || isMyCargo;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        _WorkflowHeader(
          icon: Icons.how_to_reg_rounded,
          title: user.canCreateCargo ? 'Отклики на мои грузы' : 'Мои отклики',
          subtitle: user.canCreateCargo
              ? 'Выбирайте исполнителей из откликнувшихся пользователей.'
              : 'Следите, какие заявки приняли, а какие еще ждут решения.',
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const _StatePanel(
            icon: Icons.inbox_outlined,
            title: 'Откликов пока нет',
            message:
                'Когда перевозчики начнут откликаться на грузы, список появится здесь.',
          )
        else
          ...visible.map((application) {
            final cargo = cargos.cast<CargoModel?>().firstWhere(
                  (item) => item?.id == application.cargoId,
                  orElse: () => null,
                );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicationCard(
                user: user,
                application: application,
                cargo: cargo,
                onDecision: cargo == null
                    ? null
                    : (accepted) => onDecision(application, cargo, accepted),
              ),
            );
          }),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final UserModel user;
  final CargoApplicationModel application;
  final CargoModel? cargo;
  final Future<void> Function(bool accepted)? onDecision;

  const _ApplicationCard({
    required this.user,
    required this.application,
    required this.cargo,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _applicationStatusColor(application.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.assignment_ind_rounded, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.cargoTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.canApplyToCargo
                            ? 'Ваш отклик отправлен ${DateFormat('dd.MM HH:mm').format(application.createdAt)}'
                            : '${application.applicantName} ${application.applicantUsername}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusPill(
                  label: _applicationStatusLabel(application.status),
                  color: statusColor,
                ),
              ],
            ),
            if (application.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(application.note),
            ],
            if (cargo != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                      icon: Icons.route_rounded,
                      label: '${cargo!.from} -> ${cargo!.to}'),
                  _InfoChip(
                      icon: Icons.inventory_2_outlined, label: cargo!.status),
                  if (cargo!.price != null)
                    _InfoChip(
                        icon: Icons.payments_rounded,
                        label: _formatMoney(cargo!.price!)),
                ],
              ),
            ],
            if (user.canCreateCargo && application.isPending && onDecision != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onDecision!(false),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Отклонить'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => onDecision!(true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Принять'),
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

class NotificationsSection extends StatelessWidget {
  final UserModel user;

  const NotificationsSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SiteNotificationModel>>(
      stream: SiteWorkflowRepository.instance.watchNotifications(user.uid),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <SiteNotificationModel>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          children: [
            const _WorkflowHeader(
              icon: Icons.notifications_active_outlined,
              title: 'Уведомления',
              subtitle:
                  'Сообщения о чатах, откликах, документах, статусах и оценках.',
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else if (notifications.isEmpty)
              const _StatePanel(
                icon: Icons.notifications_none_rounded,
                title: 'Пока тихо',
                message: 'Новые события по вашим грузам появятся здесь.',
              )
            else
              ...notifications.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationTile(notification: item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final SiteNotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _workflowTypeColor(notification.type, colors);
    return Card(
      color: notification.isRead ? null : color.withOpacity(0.07),
      child: ListTile(
        leading: Icon(_workflowTypeIcon(notification.type), color: color),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${notification.body}\n${DateFormat('dd.MM.yyyy HH:mm').format(notification.createdAt)}',
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? const Icon(Icons.done_all_rounded)
            : IconButton(
                tooltip: 'Отметить прочитанным',
                icon: const Icon(Icons.mark_email_read_outlined),
                onPressed: () => SiteWorkflowRepository.instance
                    .markNotificationRead(notification.id),
              ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(SiteNotificationModel notification)
      onOpenNotification;

  const _NotificationBell({
    required this.user,
    required this.onOpenNotification,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<SiteNotificationModel>>(
      stream: SiteWorkflowRepository.instance.watchNotifications(user.uid),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <SiteNotificationModel>[];
        final unread = notifications.where((item) => !item.isRead).length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Уведомления',
              icon: Icon(
                unread > 0
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
              ),
              onPressed: () {
                _markAllNotificationsRead(
                  notifications.where((item) => !item.isRead),
                );
                _showNotificationsPopup(
                  context,
                  user,
                  onOpenNotification,
                );
              },
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _showNotificationsPopup(
  BuildContext context,
  UserModel user,
  Future<void> Function(SiteNotificationModel notification) onOpenNotification,
) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.08),
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final top = MediaQuery.paddingOf(context).top + 58;
      final isCompact = size.width < 520;

      return Stack(
        children: [
          Positioned(
            top: top,
            right: isCompact ? 10 : 18,
            left: isCompact ? 10 : null,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _NotificationPopup(
                  user: user,
                  onOpenNotification: onOpenNotification,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _NotificationPopup extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(SiteNotificationModel notification)
      onOpenNotification;

  const _NotificationPopup({
    required this.user,
    required this.onOpenNotification,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 18,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StreamBuilder<List<SiteNotificationModel>>(
          stream: SiteWorkflowRepository.instance.watchNotifications(user.uid),
          builder: (context, snapshot) {
            final notifications =
                snapshot.data ?? const <SiteNotificationModel>[];
            final unread = notifications.where((item) => !item.isRead).toList();
            final visible = notifications.take(8).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Уведомления',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (unread.isNotEmpty)
                      TextButton(
                        onPressed: () => _markAllNotificationsRead(unread),
                        child: const Text('Прочитать'),
                      ),
                    IconButton(
                      tooltip: 'Закрыть',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 22),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 42,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Пока тихо',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Новые события появятся здесь.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 430),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => _NotificationMiniTile(
                        notification: visible[index],
                        onOpenNotification: onOpenNotification,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _markAllNotificationsRead(
  Iterable<SiteNotificationModel> notifications,
) async {
  for (final notification in notifications) {
    await SiteWorkflowRepository.instance.markNotificationRead(
      notification.id,
    );
  }
}

class _NotificationMiniTile extends StatelessWidget {
  final SiteNotificationModel notification;
  final Future<void> Function(SiteNotificationModel notification)
      onOpenNotification;

  const _NotificationMiniTile({
    required this.notification,
    required this.onOpenNotification,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _workflowTypeColor(notification.type, colors);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.pop(context);
        onOpenNotification(notification);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: notification.isRead
              ? colors.surfaceContainerHighest.withOpacity(0.34)
              : color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: notification.isRead
                ? Theme.of(context).dividerColor
                : color.withOpacity(0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_workflowTypeIcon(notification.type),
                  size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('dd.MM HH:mm').format(notification.createdAt),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            notification.isRead
                ? Icon(Icons.done_all_rounded,
                    size: 18, color: colors.onSurfaceVariant)
                : Icon(Icons.circle, size: 9, color: color),
          ],
        ),
      ),
    );
  }
}

class ActivitySection extends StatelessWidget {
  final UserModel user;

  const ActivitySection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityLogModel>>(
      stream: SiteWorkflowRepository.instance.watchActivity(user.uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ActivityLogModel>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          children: [
            const _WorkflowHeader(
              icon: Icons.manage_history_rounded,
              title: 'История действий',
              subtitle:
                  'Журнал изменений по грузам, откликам, документам и жалобам.',
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              const _StatePanel(
                icon: Icons.history_toggle_off_rounded,
                title: 'Истории пока нет',
                message:
                    'Когда появятся действия по вашим грузам, они будут здесь.',
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActivityTile(item: item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityLogModel item;

  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _workflowTypeColor(item.type, colors);
    return Card(
      child: ListTile(
        leading: Icon(_workflowTypeIcon(item.type), color: color),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          '${item.body}\n${item.actorName} · ${DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class AdminSection extends StatelessWidget {
  final UserModel user;
  final List<UserModel> users;
  final List<CargoModel> cargos;

  const AdminSection({
    super.key,
    required this.user,
    required this.users,
    required this.cargos,
  });

  @override
  Widget build(BuildContext context) {
    if (!user.isAdmin) {
      return const Center(
        child: _StatePanel(
          icon: Icons.lock_outline_rounded,
          title: 'Раздел недоступен',
          message: 'Модерация доступна логистам и администраторам площадки.',
        ),
      );
    }

    final carriers = users.where((item) => item.isCarrier).length;
    final logisticians = users.where((item) => item.isLogistician).length;
    return StreamBuilder<List<UserReportModel>>(
      stream: SiteWorkflowRepository.instance.watchReports(user),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? const <UserReportModel>[];
        final openReports =
            reports.where((item) => item.status != 'resolved').toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          children: [
            const _WorkflowHeader(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Админ-панель',
              subtitle: 'Быстрый контроль пользователей, грузов и жалоб.',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final cards = [
                  _AdminMetric(
                      label: 'Пользователей',
                      value: users.length.toString(),
                      icon: Icons.people_alt_outlined),
                   _AdminMetric(
                      label: 'Перевозчиков',
                      value: carriers.toString(),
                      icon: Icons.badge_outlined),
                  _AdminMetric(
                      label: 'Логистов',
                      value: logisticians.toString(),
                      icon: Icons.manage_accounts_outlined),
                  _AdminMetric(
                      label: 'Грузов',
                      value: cargos.length.toString(),
                      icon: Icons.inventory_2_outlined),
                  _AdminMetric(
                      label: 'Открытых жалоб',
                      value: openReports.length.toString(),
                      icon: Icons.report_outlined),
                ];
                return GridView.count(
                  crossAxisCount: compact ? 1 : 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: compact ? 4.5 : 1.5,
                  children: cards,
                );
              },
            ),
            const SizedBox(height: 18),
            _ProfilePanel(
              icon: Icons.report_problem_outlined,
              title: 'Жалобы пользователей (${reports.length})',
              child: reports.isEmpty
                  ? const _ProfileEmpty(
                      icon: Icons.verified_user_outlined,
                      title: 'Жалоб нет',
                      message:
                          'Когда пользователи отправят жалобу, она появится здесь.',
                    )
                  : Column(
                      children: reports
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReportTile(admin: user, report: report),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AdminMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
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

class _ReportTile extends StatelessWidget {
  final UserModel admin;
  final UserReportModel report;

  const _ReportTile({required this.admin, required this.report});

  @override
  Widget build(BuildContext context) {
    final resolved = report.status == 'resolved';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            resolved ? Icons.task_alt_rounded : Icons.report_problem_outlined,
            color: resolved
                ? const Color(0xFF16A34A)
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.reporterName} → ${report.targetName}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(report.reason),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(report.createdAt),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          resolved
              ? const _StatusPill(label: 'Закрыта', color: Color(0xFF16A34A))
              : OutlinedButton(
                  onPressed: () => SiteWorkflowRepository.instance
                      .resolveReport(admin: admin, reportId: report.id),
                  child: const Text('Закрыть'),
                ),
        ],
      ),
    );
  }
}

class _WorkflowHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WorkflowHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.11),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
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

Color _applicationStatusColor(String status) {
  switch (status) {
    case 'accepted':
      return const Color(0xFF16A34A);
    case 'declined':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF2563EB);
  }
}

String _applicationStatusLabel(String status) {
  switch (status) {
    case 'accepted':
      return 'Принят';
    case 'declined':
      return 'Отклонен';
    default:
      return 'Ожидает';
  }
}

IconData _workflowTypeIcon(String type) {
  switch (type) {
    case 'application':
      return Icons.how_to_reg_rounded;
    case 'document':
      return Icons.attach_file_rounded;
    case 'status':
      return Icons.sync_alt_rounded;
    case 'report':
      return Icons.report_problem_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _workflowTypeColor(String type, ColorScheme colors) {
  switch (type) {
    case 'application':
      return colors.primary;
    case 'document':
      return colors.tertiary;
    case 'status':
      return const Color(0xFF0891B2);
    case 'report':
      return colors.error;
    default:
      return colors.secondary;
  }
}
