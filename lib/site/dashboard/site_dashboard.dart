part of '../../main_site.dart';

enum SiteSection {
  overview,
  company,
  cargos,
  findTransport,
  myCargos,
  myTransport,
  favorites,
  chats,
  tender,
  insurance,
  legal,
  support,
  applications,
  notifications,
  users,
  activity,
  admin,
  carriers,
  sync,
}

class SiteDashboard extends StatefulWidget {
  final UserModel user;
  final String? workspaceSlug;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteDashboard({
    super.key,
    required this.user,
    required this.workspaceSlug,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SiteDashboard> createState() => _SiteDashboardState();
}

class _SiteDashboardState extends State<SiteDashboard> {
  SiteSection _section = SiteSection.overview;
  String _query = '';
  String? _status;
  CargoFilters _filters = CargoFilters.empty;
  UserModel? _selectedChatUser;

  late final Stream<List<CargoModel>> _cargosStream;
  late final Stream<List<UserModel>> _usersStream;
  late final Stream<Set<String>> _favoritesStream;
  late final Stream<List<CargoApplicationModel>> _applicationsStream;
  late final Stream<List<TransportModel>> _transportsStream;

  SiteWorkspaceConfig get _workspace =>
      siteWorkspaceFor(widget.user, widget.workspaceSlug);

  @override
  void initState() {
    super.initState();
    _cargosStream = CargoRepository.instance.watchAllCargos();
    _usersStream = UserRepository.instance.watchAllUsers();
    _favoritesStream =
        UserRepository.instance.watchFavoriteCargoIds(widget.user.uid);
    _applicationsStream =
        SiteWorkflowRepository.instance.watchApplicationsForUser(widget.user);
    _transportsStream = TransportRepository.instance.watchAvailableTransport();
  }

  List<SiteSection> get _visibleSections => _workspace.sections;

  void _selectSectionByIndex(int index) {
    final sections = _visibleSections;
    if (index < 0 || index >= sections.length) return;
    setState(() => _section = sections[index]);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 1040;

    return StreamBuilder<List<CargoModel>>(
      stream: _cargosStream,
      builder: (context, cargoSnapshot) {
        final cargos = cargoSnapshot.data ?? const <CargoModel>[];
        final cargoError = cargoSnapshot.error;

        return StreamBuilder<List<UserModel>>(
          stream: _usersStream,
          builder: (context, userSnapshot) {
            final users = userSnapshot.data ?? const <UserModel>[];
            final carriers = users.where((user) => user.isCarrier).toList();

            return StreamBuilder<Set<String>>(
              stream: _favoritesStream,
              builder: (context, favoriteSnapshot) {
                final favoriteCargoIds =
                    favoriteSnapshot.data ?? const <String>{};

                return StreamBuilder<List<CargoApplicationModel>>(
                  stream: _applicationsStream,
                  builder: (context, applicationSnapshot) {
                    final applications = applicationSnapshot.data ??
                        const <CargoApplicationModel>[];

                    return StreamBuilder<List<TransportModel>>(
                      stream: _transportsStream,
                      builder: (context, transportSnapshot) {
                        final transports =
                            transportSnapshot.data ?? const <TransportModel>[];

                        return AppResponsiveScaffold(
                          appBar: isWide
                              ? null
                              : AppBar(
                                  title: const Text('Logist App Site'),
                                  actions: _topActions(users, cargos),
                                ),
                          sidebar: _buildRail(context),
                          bottomNavigation: _buildBottomBar(),
                          floatingActionButton: _fab(context),
                          body: Column(
                            children: [
                              if (isWide)
                                _buildTopBar(
                                  context,
                                  cargoSnapshot,
                                  users,
                                  cargos,
                                ),
                              Expanded(
                                child: cargoSnapshot.connectionState ==
                                            ConnectionState.waiting &&
                                        !cargoSnapshot.hasData
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : cargoError != null
                                        ? Center(
                                            child: _StatePanel(
                                              icon: Icons.cloud_off_rounded,
                                              title: 'Данные недоступны',
                                              message: cargoError.toString(),
                                            ),
                                          )
                                        : _buildSection(
                                            cargos,
                                            carriers,
                                            users,
                                            favoriteCargoIds,
                                            applications,
                                            transports,
                                          ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _topActions(List<UserModel> users, List<CargoModel> cargos) {
    return [
      ThemeIconButton(isDark: widget.isDark, onPressed: widget.onToggleTheme),
      _NotificationBell(
        user: widget.user,
        onOpenNotification: (notification) => _openNotificationSource(
          notification,
          users,
          cargos,
        ),
      ),
      IconButton(
        tooltip: 'Мой профиль',
        icon: const Icon(Icons.account_circle_outlined),
        onPressed: () => _openProfile(widget.user),
      ),
      IconButton(
        tooltip: 'Выйти',
        icon: const Icon(Icons.logout_rounded),
        onPressed: AuthRepository.instance.signOut,
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildTopBar(
    BuildContext context,
    AsyncSnapshot<List<CargoModel>> cargoSnapshot,
    List<UserModel> users,
    List<CargoModel> cargos,
  ) {
    final colors = Theme.of(context).colorScheme;
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sectionTitle(_section),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.circle, size: 9, color: colors.secondary),
                  const SizedBox(width: 7),
                  _WorkspaceMiniBadge(workspace: _workspace),
                  const SizedBox(width: 10),
                  Text(
                    cargoSnapshot.connectionState == ConnectionState.active
                        ? 'Синхронизировано: $now'
                        : 'Подключение...',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (_canCreateCargo)
            FilledButton.icon(
              onPressed: () => _showCargoDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Груз'),
            ),
          if (_canCreateTransport) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showTransportDialog(context),
              icon: const Icon(Icons.local_shipping_rounded),
              label: const Text('Транспорт'),
            ),
          ],
          const SizedBox(width: 12),
          ..._topActions(users, cargos),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sections = _visibleSections;
    final selectedIndex = sections.indexOf(_section);
    return Container(
      width: 238,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Row(
              children: [
                const _LogoMark(isDense: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Logist App',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: NavigationRail(
              extended: true,
              minExtendedWidth: 230,
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: _selectSectionByIndex,
              labelType: NavigationRailLabelType.none,
              destinations: sections
                  .map(
                    (section) => NavigationRailDestination(
                      icon: Icon(_sectionIcon(section, selected: false)),
                      selectedIcon: Icon(_sectionIcon(section, selected: true)),
                      label: Text(_sectionTitle(section)),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _WorkspaceSidebarCard(workspace: _workspace),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _ExchangeRatePanel(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _UserBadge(
              user: widget.user,
              color: colors.primary,
              onTap: () => _openProfile(widget.user),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final sections = _visibleSections;
    final selectedIndex = sections.indexOf(_section);
    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: _selectSectionByIndex,
      destinations: sections
          .map(
            (section) => NavigationDestination(
              icon: Icon(_sectionIcon(section, selected: false)),
              selectedIcon: Icon(_sectionIcon(section, selected: true)),
              label: _sectionShortTitle(section),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSection(
    List<CargoModel> cargos,
    List<UserModel> carriers,
    List<UserModel> users,
    Set<String> favoriteCargoIds,
    List<CargoApplicationModel> applications,
    List<TransportModel> transports,
  ) {
    switch (_section) {
      case SiteSection.overview:
        return OverviewSection(
          workspace: _workspace,
          cargos: _personalCargos(cargos),
          carriers: carriers,
          user: widget.user,
          onCreateCargo: widget.user.canCreateCargo
              ? () => _showCargoDialog(context)
              : null,
          onOpenCargo: () => setState(() => _section = SiteSection.myCargos),
          onOpenRecentCargo: (cargo) {
            setState(() {
              _section = SiteSection.myCargos;
              _query = cargo.title;
              _status = null;
              _filters = CargoFilters.empty;
            });
          },
          onOpenSection: (section) {
            if (!_visibleSections.contains(section)) return;
            setState(() => _section = section);
          },
          onOpenSettings: () => _openProfileSettings(widget.user),
          onOpenMyCargosWithStatus: (status) {
            setState(() {
              _section = SiteSection.myCargos;
              _status = status;
              _filters = CargoFilters.empty;
              _query = '';
            });
          },
          onOpenMyCargosActive: () {
            setState(() {
              _section = SiteSection.myCargos;
              _status = null;
              _filters = const CargoFilters(onlyActive: true);
              _query = '';
            });
          },
        );
      case SiteSection.company:
        return CompanySection(
          user: widget.user,
          users: users,
          cargos: _personalCargos(cargos),
          onOpenProfile: () => _openProfile(widget.user),
          onOpenChats: () => setState(() => _section = SiteSection.chats),
        );
      case SiteSection.myCargos:
        final personalCargos = _filteredCargos(_personalCargos(cargos));
        return CargosSection(
          cargos: personalCargos,
          allCargos: _personalCargos(cargos),
          carriers: carriers,
          user: widget.user,
          query: _query,
          status: _status,
          filters: _filters,
          title: 'Мои актуальные грузы',
          emptyTitle: 'У вас нет актуальных грузов',
          emptyMessage: widget.user.canApplyToCargo
              ? 'Назначенные заявки появятся здесь.'
              : 'Для добавления груза нажмите плюс рядом с пунктом меню.',
          onQueryChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _status = value),
          onFiltersChanged: (value) => setState(() => _filters = value),
          onAddCargo: () => _showCargoDialog(context),
          onAssignCarrier: _assignCarrier,
          onChangeStatus: _changeStatus,
          onDeleteCargo: _deleteCargo,
          onOpenChat: (cargo) => _openChatForCargo(cargo, users),
          onOpenProfile: _openProfile,
          favoriteCargoIds: favoriteCargoIds,
          onToggleFavorite: _toggleFavoriteCargo,
          applications: applications,
          onApplyToCargo: _applyToCargo,
          onApplicationDecision: _decideApplication,
        );
      case SiteSection.cargos:
        final filtered = _filteredCargos(cargos);
        return CargosSection(
          cargos: filtered,
          allCargos: cargos,
          carriers: carriers,
          user: widget.user,
          query: _query,
          status: _status,
          filters: _filters,
          onQueryChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _status = value),
          onFiltersChanged: (value) => setState(() => _filters = value),
          onAddCargo: () => _showCargoDialog(context),
          onAssignCarrier: _assignCarrier,
          onChangeStatus: _changeStatus,
          onDeleteCargo: _deleteCargo,
          onOpenChat: (cargo) => _openChatForCargo(cargo, users),
          onOpenProfile: _openProfile,
          favoriteCargoIds: favoriteCargoIds,
          onToggleFavorite: _toggleFavoriteCargo,
          applications: applications,
          onApplyToCargo: _applyToCargo,
          onApplicationDecision: _decideApplication,
        );
      case SiteSection.tender:
        return TenderSection(user: widget.user);
      case SiteSection.applications:
        return ApplicationsSection(
          user: widget.user,
          cargos: cargos,
          applications: applications,
          onDecision: _decideApplication,
        );
      case SiteSection.chats:
        return ChatsSection(
          users: users,
          user: widget.user,
          initialPeer: _selectedChatUser,
        );
      case SiteSection.carriers:
        return CarriersSection(
          cargos: cargos,
          carriers: carriers,
          user: widget.user,
          onAssignCarrier: _assignCarrier,
        );
      case SiteSection.notifications:
        return NotificationsSection(user: widget.user);
      case SiteSection.users:
        return UsersSection(
          users: users,
          currentUser: widget.user,
          user: widget.user,
          onOpenProfile: _openProfile,
          onOpenChat: _openChatWithUser,
        );
      case SiteSection.favorites:
        final favoriteCargos = _filteredCargos(cargos
            .where((cargo) => favoriteCargoIds.contains(cargo.id))
            .toList());
        return CargosSection(
          cargos: favoriteCargos,
          allCargos: cargos
              .where((cargo) => favoriteCargoIds.contains(cargo.id))
              .toList(),
          carriers: carriers,
          user: widget.user,
          query: _query,
          status: _status,
          filters: _filters,
          title: 'Отмеченные заявки',
          emptyTitle: 'Отмеченных грузов пока нет',
          emptyMessage:
              'Нажмите галочку в списке грузов, чтобы сохранить заявку здесь.',
          showAddButton: false,
          onQueryChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _status = value),
          onFiltersChanged: (value) => setState(() => _filters = value),
          onAddCargo: () => _showCargoDialog(context),
          onAssignCarrier: _assignCarrier,
          onChangeStatus: _changeStatus,
          onDeleteCargo: _deleteCargo,
          onOpenChat: (cargo) => _openChatForCargo(cargo, users),
          onOpenProfile: _openProfile,
          favoriteCargoIds: favoriteCargoIds,
          onToggleFavorite: _toggleFavoriteCargo,
          applications: applications,
          onApplyToCargo: _applyToCargo,
          onApplicationDecision: _decideApplication,
        );
      case SiteSection.activity:
        return ActivitySection(user: widget.user);
      case SiteSection.findTransport:
        return FindTransportSection(
          user: widget.user,
          transports: transports,
          onOpenProfile: _openProfile,
          onOpenChat: _openChatWithUser,
        );
      case SiteSection.myTransport:
        return MyTransportSection(
          user: widget.user,
          onAddTransport: () => _showTransportDialog(context),
          onOpenProfile: _openProfile,
        );
      case SiteSection.insurance:
        return ServiceRequestSection(
          user: widget.user,
          type: 'insurance',
          title: 'Страхование груза',
          subtitle:
              'Отправьте параметры перевозки, чтобы зафиксировать заявку на полис и историю обращения.',
          icon: Icons.verified_user_outlined,
          subjectLabel: 'Что страхуем',
          messageLabel: 'Условия и комментарии',
          showRouteFields: true,
          showAmountField: true,
        );
      case SiteSection.legal:
        return ServiceRequestSection(
          user: widget.user,
          type: 'legal',
          title: 'Помощь юриста',
          subtitle:
              'Создайте обращение по спору, договору, оплате или проверке контрагента.',
          icon: Icons.gavel_outlined,
          subjectLabel: 'Тема обращения',
          messageLabel: 'Опишите ситуацию',
        );
      case SiteSection.support:
        return ServiceRequestSection(
          user: widget.user,
          type: 'support',
          title: 'Техподдержка',
          subtitle:
              'Сообщите о проблеме сайта, аккаунта, синхронизации или данных в кабинете.',
          icon: Icons.support_agent_outlined,
          subjectLabel: 'Что не работает',
          messageLabel: 'Шаги, ошибка и ожидаемый результат',
        );
      case SiteSection.admin:
        return AdminSection(user: widget.user, users: users, cargos: cargos);
      case SiteSection.sync:
        return SyncSection(
            cargos: cargos, carriers: carriers, user: widget.user);
    }
  }

  Future<void> _openChatForCargo(
    CargoModel cargo,
    List<UserModel> users,
  ) async {
    final peerId = cargo.ownerId == widget.user.uid
        ? cargo.carrierId
        : cargo.carrierId == widget.user.uid
            ? cargo.ownerId
            : (cargo.ownerId ?? cargo.carrierId);
    final peer = users.cast<UserModel?>().firstWhere(
          (user) => user?.uid == peerId,
          orElse: () => null,
        );
    if (peer == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для чата сначала нужен второй участник заявки'),
        ),
      );
      return;
    }
    await _openChatWithUser(peer);
  }

  Future<void> _openChatWithUser(UserModel user) async {
    setState(() {
      _selectedChatUser = user;
      _section = SiteSection.chats;
    });
  }

  Future<void> _openProfile(UserModel profile) async {
    context
        .push('/profile/${profile.profileSlug}/${ProfileSection.account.path}');
  }

  Future<void> _openProfileSettings(UserModel profile) async {
    context.push(
      '/profile/${profile.profileSlug}/${ProfileSection.settings.path}',
    );
  }

  Future<void> _openNotificationSource(
    SiteNotificationModel notification,
    List<UserModel> users,
    List<CargoModel> cargos,
  ) async {
    await SiteWorkflowRepository.instance.markNotificationRead(notification.id);
    if (!mounted) return;

    final relatedId = notification.relatedId;
    switch (notification.type) {
      case 'chat':
        final peerId = relatedId
            ?.split('_')
            .where((id) => id.isNotEmpty && id != widget.user.uid)
            .firstOrNull;
        final peer = users.cast<UserModel?>().firstWhere(
              (user) => user?.uid == peerId,
              orElse: () => null,
            );
        if (peer != null) {
          await _openChatWithUser(peer);
          return;
        }
        setState(() => _section = SiteSection.chats);
        return;
      case 'application':
        setState(() => _section = SiteSection.applications);
        return;
      case 'document':
      case 'status':
        final cargo = cargos.cast<CargoModel?>().firstWhere(
              (item) => item?.id == relatedId,
              orElse: () => null,
            );
        setState(() {
          _query = cargo?.title ?? '';
          _section = cargo != null &&
                  (cargo.ownerId == widget.user.uid ||
                      cargo.carrierId == widget.user.uid)
              ? SiteSection.myCargos
              : SiteSection.cargos;
        });
        return;
      case 'rating':
        final profile = users.cast<UserModel?>().firstWhere(
              (user) => user?.uid == relatedId,
              orElse: () => null,
            );
        if (profile != null) {
          await _openProfile(profile);
          return;
        }
        setState(() => _section = SiteSection.users);
        return;
      default:
        setState(() => _section = SiteSection.activity);
    }
  }

  bool get _canCreateCargo =>
      widget.user.canCreateCargo &&
      (_section == SiteSection.myCargos || _section == SiteSection.cargos);

  bool get _canCreateTransport =>
      widget.user.canApplyToCargo &&
      (_section == SiteSection.myTransport ||
          _section == SiteSection.findTransport);

  Widget? _fab(BuildContext context) {
    if (_canCreateCargo) {
      return FloatingActionButton.extended(
        onPressed: () => _showCargoDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Груз'),
      );
    }
    if (_canCreateTransport) {
      return FloatingActionButton.extended(
        onPressed: () => _showTransportDialog(context),
        icon: const Icon(Icons.local_shipping_rounded),
        label: const Text('Транспорт'),
      );
    }
    return null;
  }

  List<CargoModel> _personalCargos(List<CargoModel> cargos) {
    return cargos.where((cargo) {
      final isMyCarrierCargo =
          widget.user.canApplyToCargo && cargo.carrierId == widget.user.uid;
      final isMyOwnerCargo =
          widget.user.canCreateCargo && cargo.ownerId == widget.user.uid;
      return isMyCarrierCargo || isMyOwnerCargo;
    }).toList();
  }

  List<CargoModel> _filteredCargos(List<CargoModel> cargos) {
    final query = _query.trim().toLowerCase();
    final from = _filters.from.trim().toLowerCase();
    final to = _filters.to.trim().toLowerCase();
    final bodyType = _filters.bodyType.trim().toLowerCase();

    return cargos.where((cargo) {
      // Stage 2A: Visibility rules for "Find Cargo" (SiteSection.cargos)
      if (_section == SiteSection.cargos) {
        // Only show published or active public cargos
        final publicStatuses = [
          CargoStatus.published,
          CargoStatus.hasApplications,
          CargoStatus.executorSelected,
          CargoStatus.waitingConfirmation,
        ];
        if (!publicStatuses.contains(cargo.status)) return false;

        // Don't show finished or cancelled
        if (cargo.isFinished || cargo.isCancelled) return false;
      }

      // Basic Status Filter (from status chips)
      if (_status != null && cargo.status != _status) return false;

      // Advanced Filters
      if (_filters.onlyWithoutCarrier && cargo.carrierId != null) return false;
      if (_filters.onlyActive && !cargo.isActive) return false;

      // Route Filters
      if (from.isNotEmpty || to.isNotEmpty) {
        final cargoFrom = cargo.from.toLowerCase();
        final cargoTo = cargo.to.toLowerCase();

        bool matches = true;
        if (from.isNotEmpty && !cargoFrom.contains(from)) matches = false;
        if (to.isNotEmpty && !cargoTo.contains(to)) matches = false;

        if (!matches && _filters.isTwoWaySearch) {
          // Check reverse direction
          bool matchesReverse = true;
          if (from.isNotEmpty && !cargoTo.contains(from))
            matchesReverse = false;
          if (to.isNotEmpty && !cargoFrom.contains(to)) matchesReverse = false;
          matches = matchesReverse;
        }

        if (!matches) return false;
      }

      // Cargo Specs Filters
      if (bodyType.isNotEmpty &&
          (cargo.bodyType?.toLowerCase() ?? '') != bodyType) return false;
      if (_filters.truckType != null && cargo.truckType != _filters.truckType)
        return false;
      if (_filters.shipmentType != null &&
          cargo.shipmentType != _filters.shipmentType) return false;
      if (_filters.carCount != null && cargo.carCount != _filters.carCount)
        return false;

      // Weight & Volume
      if (_filters.minWeight != null &&
          (cargo.weightKg ?? 0) < _filters.minWeight!) return false;
      if (_filters.maxWeight != null &&
          (cargo.weightKg ?? double.infinity) > _filters.maxWeight!)
        return false;
      if (_filters.minVolume != null &&
          (cargo.volumeM3 ?? 0) < _filters.minVolume!) return false;
      if (_filters.maxVolume != null &&
          (cargo.volumeM3 ?? double.infinity) > _filters.maxVolume!)
        return false;

      // Price & Payment
      if (_filters.priceNegotiable) {
        if (cargo.price != null && cargo.price! > 0) return false;
      } else {
        if (_filters.minPrice != null &&
            (cargo.price ?? 0) < _filters.minPrice!) return false;
        if (_filters.maxPrice != null &&
            (cargo.price ?? double.infinity) > _filters.maxPrice!) return false;
        if (_filters.currency != null && cargo.currency != _filters.currency)
          return false;
      }

      // Badges & Readiness
      if (_filters.isUrgent && !cargo.isUrgent) return false;
      if (_filters.isHumanitarian && !cargo.isHumanitarian) return false;
      if (_filters.hasPhoto && cargo.photos.isEmpty) return false;
      if (_filters.isReady != null && cargo.isReady != _filters.isReady)
        return false;

      // Date
      if (_filters.loadingDate != null) {
        if (cargo.loadingDate == null) return false;
        final cargoDate = DateTime(cargo.loadingDate!.year,
            cargo.loadingDate!.month, cargo.loadingDate!.day);
        final filterDate = DateTime(_filters.loadingDate!.year,
            _filters.loadingDate!.month, _filters.loadingDate!.day);
        if (cargoDate != filterDate) return false;
      }

      // Query Search
      if (query.isEmpty) return true;
      return cargo.title.toLowerCase().contains(query) ||
          cargo.from.toLowerCase().contains(query) ||
          cargo.to.toLowerCase().contains(query) ||
          (cargo.bodyType?.toLowerCase().contains(query) ?? false) ||
          (cargo.carrierName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _showCargoDialog(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AddCargoDialog(ownerId: widget.user.uid),
    );

    if (!mounted || created != true) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(content: Text('Груз создан и синхронизирован')),
    );
  }

  Future<void> _showTransportDialog(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AddTransportDialog(owner: widget.user),
    );

    if (!mounted || created != true) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(content: Text('Транспорт добавлен в базу')),
    );
  }

  Future<void> _toggleFavoriteCargo(CargoModel cargo, bool favorite) async {
    try {
      await UserRepository.instance.toggleFavoriteCargo(
        uid: widget.user.uid,
        cargo: cargo,
        favorite: favorite,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось обновить отметку: $error')),
      );
    }
  }

  Future<void> _assignCarrier(CargoModel cargo, UserModel carrier) async {
    try {
      await CargoWorkflowService.instance.assignDriver(
        cargo: cargo,
        driver: carrier,
        actor: widget.user,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${carrier.displayName} назначен на груз')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось назначить перевозчика: $error')),
      );
    }
  }

  Future<void> _changeStatus(CargoModel cargo, String status) async {
    try {
      await CargoWorkflowService.instance.updateStatus(
        cargo: cargo,
        actor: widget.user,
        newStatus: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Статус обновлен: $status')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось обновить статус: $error')),
      );
    }
  }

  Future<void> _deleteCargo(CargoModel cargo) async {
    try {
      await CargoRepository.instance.deleteCargo(cargo.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Груз удален')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить груз: $error')),
      );
    }
  }

  Future<void> _applyToCargo(CargoModel cargo, String note) async {
    try {
      await SiteWorkflowRepository.instance.applyToCargo(
        cargo: cargo,
        applicant: widget.user,
        note: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отклик отправлен логисту')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить отклик: $error')),
      );
    }
  }

  Future<void> _decideApplication(
    CargoApplicationModel application,
    CargoModel cargo,
    bool accepted,
  ) async {
    try {
      await SiteWorkflowRepository.instance.decideApplication(
        application: application,
        cargo: cargo,
        owner: widget.user,
        accepted: accepted,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Отклик принят' : 'Отклик отклонен'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось обработать отклик: $error')),
      );
    }
  }
}

String _sectionTitle(SiteSection section) {
  switch (section) {
    case SiteSection.overview:
      return 'Кабинет';
    case SiteSection.company:
      return 'Моя компания';
    case SiteSection.myCargos:
      return 'Мои грузы';
    case SiteSection.cargos:
      return 'Найти груз';
    case SiteSection.tender:
      return 'Тендеры';
    case SiteSection.applications:
      return 'Отклики';
    case SiteSection.chats:
      return 'Чаты';
    case SiteSection.notifications:
      return 'Уведомления';
    case SiteSection.carriers:
      return 'Перевозчики';
    case SiteSection.users:
      return 'Пользователи';
    case SiteSection.favorites:
      return 'Отмеченные';
    case SiteSection.activity:
      return 'История';
    case SiteSection.findTransport:
      return 'Найти транспорт';
    case SiteSection.myTransport:
      return 'Мой транспорт';
    case SiteSection.insurance:
      return 'Страхование';
    case SiteSection.legal:
      return 'Помощь юриста';
    case SiteSection.support:
      return 'Техподдержка';
    case SiteSection.admin:
      return 'Админ';
    case SiteSection.sync:
      return 'Синхронизация';
  }
}

String _sectionShortTitle(SiteSection section) {
  switch (section) {
    case SiteSection.overview:
      return 'Кабинет';
    case SiteSection.company:
      return 'Компания';
    case SiteSection.myCargos:
      return 'Мои';
    case SiteSection.cargos:
      return 'Грузы';
    case SiteSection.tender:
      return 'Тендер';
    case SiteSection.applications:
      return 'Отклики';
    case SiteSection.chats:
      return 'Чаты';
    case SiteSection.notifications:
      return 'Инфо';
    case SiteSection.carriers:
      return 'Парк';
    case SiteSection.users:
      return 'Люди';
    case SiteSection.favorites:
      return 'Отмеченные';
    case SiteSection.activity:
      return 'История';
    case SiteSection.findTransport:
      return 'Поиск ТС';
    case SiteSection.myTransport:
      return 'Мои ТС';
    case SiteSection.insurance:
      return 'Страхование';
    case SiteSection.legal:
      return 'Юрист';
    case SiteSection.support:
      return 'Поддержка';
    case SiteSection.admin:
      return 'Админ';
    case SiteSection.sync:
      return 'Sync';
  }
}

IconData _sectionIcon(SiteSection section, {required bool selected}) {
  switch (section) {
    case SiteSection.overview:
      return selected
          ? Icons.space_dashboard_rounded
          : Icons.space_dashboard_outlined;
    case SiteSection.company:
      return selected ? Icons.business_rounded : Icons.business_outlined;
    case SiteSection.myCargos:
      return selected ? Icons.inventory_rounded : Icons.inventory_2_outlined;
    case SiteSection.cargos:
      return selected ? Icons.inventory_2_rounded : Icons.inventory_2_outlined;
    case SiteSection.tender:
      return selected ? Icons.gavel_rounded : Icons.gavel_outlined;
    case SiteSection.applications:
      return selected ? Icons.how_to_reg_rounded : Icons.how_to_reg_outlined;
    case SiteSection.chats:
      return selected ? Icons.forum_rounded : Icons.forum_outlined;
    case SiteSection.notifications:
      return selected
          ? Icons.notifications_active_rounded
          : Icons.notifications_none_rounded;
    case SiteSection.carriers:
      return selected ? Icons.badge_rounded : Icons.badge_outlined;
    case SiteSection.users:
      return selected ? Icons.badge_rounded : Icons.badge_outlined;
    case SiteSection.favorites:
      return selected ? Icons.star_rounded : Icons.star_border_rounded;
    case SiteSection.activity:
      return selected ? Icons.manage_history_rounded : Icons.history_rounded;
    case SiteSection.findTransport:
      return selected
          ? Icons.travel_explore_rounded
          : Icons.travel_explore_outlined;
    case SiteSection.myTransport:
      return selected ? Icons.garage_rounded : Icons.garage_outlined;
    case SiteSection.insurance:
      return selected
          ? Icons.verified_user_rounded
          : Icons.verified_user_outlined;
    case SiteSection.legal:
      return selected ? Icons.gavel_rounded : Icons.gavel_outlined;
    case SiteSection.support:
      return selected
          ? Icons.support_agent_rounded
          : Icons.support_agent_outlined;
    case SiteSection.admin:
      return selected
          ? Icons.admin_panel_settings_rounded
          : Icons.admin_panel_settings_outlined;
    case SiteSection.sync:
      return selected ? Icons.sync_rounded : Icons.sync_outlined;
  }
}
