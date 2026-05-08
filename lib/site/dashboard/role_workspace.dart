part of '../../main_site.dart';

class SiteWorkspaceConfig {
  final String slug;
  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<String> capabilities;
  final List<String> restrictions;
  final List<SiteSection> sections;
  final List<SiteSection> primarySections;

  const SiteWorkspaceConfig({
    required this.slug,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.capabilities,
    required this.restrictions,
    required this.sections,
    required this.primarySections,
  });
}

SiteWorkspaceConfig siteWorkspaceFor(UserModel user, [String? requestedSlug]) {
  final allowed = _allowedWorkspaceSlugs(user);
  final slug = requestedSlug != null && allowed.contains(requestedSlug)
      ? requestedSlug
      : allowed.first;
  return _workspaceBySlug(slug);
}

String siteDashboardPathFor(UserModel user, [String? requestedSlug]) {
  if (user.isAdmin) return '/admin';
  final workspace = siteWorkspaceFor(user, requestedSlug);
  return '/dashboard/${workspace.slug}';
}

List<String> _allowedWorkspaceSlugs(UserModel user) {
  final slugs = <String>[];
  if (user.isLawyer) slugs.add('lawyer');
  if (user.isLogistician) slugs.add('logistician');
  if (user.isCargoOwner) slugs.add('cargo-owner');
  if (user.isForwarder) slugs.add('forwarder');
  if (user.isCarrier) slugs.add('carrier');
  if (slugs.isEmpty) slugs.add('logistician');
  return slugs;
}

SiteWorkspaceConfig _workspaceBySlug(String slug) {
  switch (slug) {
    case 'lawyer':
      return const SiteWorkspaceConfig(
        slug: 'lawyer',
        title: 'Кабинет юриста',
        shortTitle: 'Юрист',
        subtitle:
            'Юридические обращения, споры, договоры и консультации пользователей.',
        icon: Icons.balance_rounded,
        accent: Color(0xFF7C3AED),
        capabilities: [
          'Видит юридические обращения пользователей',
          'Общается с клиентами в чатах',
          'Проверяет профили и историю контрагентов',
          'Создает обращения в поддержку'
        ],
        restrictions: [
          'Не создает грузы',
          'Не назначает перевозчиков',
          'Не управляет транспортом'
        ],
        sections: [
          SiteSection.overview,
          SiteSection.legal,
          SiteSection.chats,
          SiteSection.users,
          SiteSection.support,
        ],
        primarySections: [
          SiteSection.legal,
          SiteSection.chats,
          SiteSection.users,
        ],
      );
    case 'carrier':
      return const SiteWorkspaceConfig(
        slug: 'carrier',
        title: 'Кабинет перевозчика',
        shortTitle: 'Перевозчик',
        subtitle:
            'Поиск грузов, отклики, свой транспорт, рейсы и связь с логистами.',
        icon: Icons.local_shipping_rounded,
        accent: Color(0xFF0891B2),
        capabilities: [
          'Ищет доступные грузы',
          'Откликается на заявки',
          'Ведет свой транспорт',
          'Обновляет статусы назначенных рейсов'
        ],
        restrictions: [
          'Не создает чужие грузы',
          'Не назначает других перевозчиков'
        ],
        sections: [
          SiteSection.overview,
          SiteSection.cargos,
          SiteSection.myCargos,
          SiteSection.myTransport,
          SiteSection.findTransport,
          SiteSection.favorites,
          SiteSection.chats,
          SiteSection.tender,
          SiteSection.insurance,
          SiteSection.legal,
          SiteSection.support,
        ],
        primarySections: [
          SiteSection.cargos,
          SiteSection.myCargos,
          SiteSection.myTransport,
        ],
      );
    case 'cargo-owner':
      return const SiteWorkspaceConfig(
        slug: 'cargo-owner',
        title: 'Кабинет грузовладельца',
        shortTitle: 'Грузовладелец',
        subtitle:
            'Создание грузов, выбор исполнителей, страхование и контроль перевозок.',
        icon: Icons.inventory_2_rounded,
        accent: Color(0xFF2563EB),
        capabilities: [
          'Создает грузы',
          'Выбирает перевозчиков',
          'Сохраняет избранные предложения',
          'Оформляет страховые и юридические заявки'
        ],
        restrictions: [
          'Не публикует транспорт как перевозчик без смешанной роли',
          'Не модерирует пользователей'
        ],
        sections: [
          SiteSection.overview,
          SiteSection.company,
          SiteSection.myCargos,
          SiteSection.cargos,
          SiteSection.findTransport,
          SiteSection.favorites,
          SiteSection.chats,
          SiteSection.tender,
          SiteSection.insurance,
          SiteSection.legal,
          SiteSection.carriers,
          SiteSection.support,
        ],
        primarySections: [
          SiteSection.myCargos,
          SiteSection.findTransport,
          SiteSection.insurance,
        ],
      );
    case 'forwarder':
      return const SiteWorkspaceConfig(
        slug: 'forwarder',
        title: 'Кабинет экспедитора',
        shortTitle: 'Экспедитор',
        subtitle:
            'Подбор грузов и транспорта, сопровождение рейсов и коммуникация.',
        icon: Icons.route_rounded,
        accent: Color(0xFFF97316),
        capabilities: [
          'Ищет грузы и транспорт',
          'Откликается на заявки',
          'Сопровождает рейсы',
          'Работает с чатами и документами'
        ],
        restrictions: [
          'Создание грузов доступно только грузовладельцу или логисту',
          'Админ-доступ закрыт'
        ],
        sections: [
          SiteSection.overview,
          SiteSection.company,
          SiteSection.cargos,
          SiteSection.myCargos,
          SiteSection.findTransport,
          SiteSection.myTransport,
          SiteSection.favorites,
          SiteSection.chats,
          SiteSection.tender,
          SiteSection.insurance,
          SiteSection.legal,
          SiteSection.support,
        ],
        primarySections: [
          SiteSection.cargos,
          SiteSection.findTransport,
          SiteSection.chats,
        ],
      );
    case 'logistician':
    default:
      return const SiteWorkspaceConfig(
        slug: 'logistician',
        title: 'Кабинет логиста',
        shortTitle: 'Логист',
        subtitle:
            'Создание грузов, назначение исполнителей, статусы, документы и аналитика.',
        icon: Icons.manage_accounts_rounded,
        accent: Color(0xFF2563EB),
        capabilities: [
          'Создает и ведет грузы',
          'Назначает перевозчиков',
          'Следит за статусами и документами',
          'Общается с пользователями'
        ],
        restrictions: [
          'Не имеет админ-панели без отдельного права',
          'Не работает как юрист без роли юриста'
        ],
        sections: [
          SiteSection.overview,
          SiteSection.company,
          SiteSection.myCargos,
          SiteSection.cargos,
          SiteSection.findTransport,
          SiteSection.favorites,
          SiteSection.chats,
          SiteSection.tender,
          SiteSection.insurance,
          SiteSection.legal,
          SiteSection.carriers,
          SiteSection.users,
          SiteSection.support,
        ],
        primarySections: [
          SiteSection.myCargos,
          SiteSection.findTransport,
          SiteSection.carriers,
        ],
      );
  }
}

class _WorkspaceMiniBadge extends StatelessWidget {
  final SiteWorkspaceConfig workspace;

  const _WorkspaceMiniBadge({required this.workspace});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: workspace.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: workspace.accent.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(workspace.icon, size: 14, color: workspace.accent),
          const SizedBox(width: 6),
          Text(
            workspace.shortTitle,
            style: TextStyle(
              color: workspace.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSidebarCard extends StatelessWidget {
  final SiteWorkspaceConfig workspace;

  const _WorkspaceSidebarCard({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: workspace.accent.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: workspace.accent.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: workspace.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(workspace.icon, color: workspace.accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspace.shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  workspace.primarySections
                      .map(_sectionShortTitle)
                      .take(2)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoleWorkspaceHero extends StatelessWidget {
  final SiteWorkspaceConfig workspace;
  final UserModel user;
  final ValueChanged<SiteSection> onOpenSection;

  const RoleWorkspaceHero({
    required this.workspace,
    required this.user,
    required this.onOpenSection,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: workspace.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(workspace.icon, color: workspace.accent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вы работаете как: ${workspace.shortTitle}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workspace.subtitle,
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
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final left = _RoleAbilityPanel(
                title: 'Можно',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF16A34A),
                items: workspace.capabilities,
              );
              final right = _RoleAbilityPanel(
                title: 'Недоступно в этой роли',
                icon: Icons.block_rounded,
                color: colors.onSurfaceVariant,
                items: workspace.restrictions,
              );
              if (compact) {
                return Column(
                  children: [left, const SizedBox(height: 12), right],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 12),
                  Expanded(child: right),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: workspace.primarySections.map((section) {
              return AppButton(
                label: _sectionTitle(section),
                icon: _sectionIcon(section, selected: true),
                variant: AppButtonVariant.secondary,
                onPressed: () => onOpenSection(section),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleAbilityPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _RoleAbilityPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: color)),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
