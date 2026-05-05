part of '../../main_site.dart';

enum ProfileSection {
  account('cabinet', 'Кабинет', Icons.account_circle_outlined),
  employees('team', 'Сотрудники', Icons.people_alt_outlined),
  vehicles('vehicles', 'Транспорт', Icons.local_shipping_outlined),
  cargos('cargos', 'Мои грузы', Icons.inventory_2_outlined),
  favorites('favorites', 'Отмеченные', Icons.star_border_rounded),
  settings('settings', 'Настройки', Icons.tune_rounded);

  final String path;
  final String label;
  final IconData icon;

  const ProfileSection(this.path, this.label, this.icon);

  static ProfileSection fromPath(String? value) {
    return ProfileSection.values.firstWhere(
      (section) => section.path == value,
      orElse: () => ProfileSection.account,
    );
  }
}

class UserProfilePage extends ConsumerStatefulWidget {
  final String? nickname;
  final ProfileSection section;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const UserProfilePage({
    super.key,
    required this.nickname,
    required this.section,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final _aboutController = TextEditingController();
  final _nameController = TextEditingController();
  final _carController = TextEditingController();
  final _picker = ImagePicker();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isRating = false;
  XFile? _selectedAvatar;
  int? _selectedScore;

  @override
  void dispose() {
    _aboutController.dispose();
    _nameController.dispose();
    _carController.dispose();
    super.dispose();
  }

  void _startEditing(UserModel user) {
    _nameController.text = user.name ?? '';
    _aboutController.text = user.aboutMe ?? '';
    _carController.text = user.car ?? '';
    setState(() {
      _selectedAvatar = null;
      _isEditing = true;
    });
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 86,
    );
    if (image == null || !mounted) return;
    setState(() => _selectedAvatar = image);
  }

  Future<void> _saveProfile(UserModel currentUser) async {
    setState(() => _isLoading = true);
    try {
      await UserRepository.instance.updateProfile(
        user: currentUser,
        name: _nameController.text,
        aboutMe: _aboutController.text,
        car: _carController.text,
        avatar: _selectedAvatar,
      );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _selectedAvatar = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль обновлен')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rate(UserModel target, UserModel currentUser, int score) async {
    if (_isRating || target.uid == currentUser.uid) return;
    setState(() {
      _selectedScore = score;
      _isRating = true;
    });
    try {
      await UserRepository.instance.rateUser(
        target: target,
        raterId: currentUser.uid,
        score: score,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Оценка $score сохранена')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось поставить оценку: $error')),
      );
    } finally {
      if (mounted) setState(() => _isRating = false);
    }
  }

  Future<void> _reportUser(UserModel target, UserModel currentUser) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Жалоба на ${target.displayName}'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Причина жалобы',
              hintText: 'Опишите, что произошло',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            icon: const Icon(Icons.report_outlined),
            label: const Text('Отправить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.trim().isEmpty) return;

    try {
      await SiteWorkflowRepository.instance.reportUser(
        reporter: currentUser,
        target: target,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Жалоба отправлена на модерацию')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить жалобу: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.nickname?.replaceFirst('@', '');

    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль @$username'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          ThemeIconButton(
            isDark: widget.isDark,
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: UserRepository.instance.watchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final users = snapshot.data ?? const <UserModel>[];
          final profileUser = _findProfileUser(users);
          if (profileUser == null) {
            return _ProfileNotFound(username: username);
          }

          return StreamBuilder<UserModel?>(
            stream: AuthRepository.instance.watchCurrentUser(),
            builder: (context, authSnapshot) {
              final currentUser = authSnapshot.data;
              final isOwner = currentUser?.uid == profileUser.uid;

              return ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 48),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHero(
                            user: profileUser,
                            isOwner: isOwner,
                            section: widget.section,
                            onEdit: () => _startEditing(profileUser),
                            onDashboard: () => context.go('/dashboard'),
                            onReport: currentUser == null || isOwner
                                ? null
                                : () => _reportUser(profileUser, currentUser),
                          ),
                          const SizedBox(height: 14),
                          _ProfileTabs(
                            profile: profileUser,
                            selected: widget.section,
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            profileUser: profileUser,
                            currentUser: currentUser,
                            users: users,
                            isOwner: isOwner,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required UserModel profileUser,
    required UserModel? currentUser,
    required List<UserModel> users,
    required bool isOwner,
  }) {
    switch (widget.section) {
      case ProfileSection.account:
        return _ProfileAccountSection(
          profileUser: profileUser,
          currentUser: currentUser,
          isOwner: isOwner,
          isEditing: _isEditing,
          isLoading: _isLoading,
          isRating: _isRating,
          selectedScore: _selectedScore,
          selectedAvatar: _selectedAvatar,
          nameController: _nameController,
          aboutController: _aboutController,
          carController: _carController,
          onEdit: () => _startEditing(profileUser),
          onPickAvatar: _pickAvatar,
          onCancel: () => setState(() {
            _isEditing = false;
            _selectedAvatar = null;
          }),
          onSave: currentUser == null ? null : () => _saveProfile(currentUser),
          onRate: currentUser == null
              ? null
              : (score) => _rate(profileUser, currentUser, score),
        );
      case ProfileSection.employees:
        return _ProfilePeopleSection(
          title: 'Сотрудники платформы',
          users: users,
          currentUser: currentUser,
          filter: (user) => true,
        );
      case ProfileSection.vehicles:
        return _ProfilePeopleSection(
          title: 'Транспорт и бригады',
          users: users,
          currentUser: currentUser,
          filter: (user) => user.isDriver,
          showVehicle: true,
        );
      case ProfileSection.cargos:
        return _ProfileCargosSection(
          profileUser: profileUser,
          currentUser: currentUser,
          favoritesOnly: false,
        );
      case ProfileSection.favorites:
        return _ProfileCargosSection(
          profileUser: profileUser,
          currentUser: currentUser,
          favoritesOnly: true,
        );
      case ProfileSection.settings:
        return _ProfileSettingsSection(
          profileUser: profileUser,
          isOwner: isOwner,
        );
    }
  }

  UserModel? _findProfileUser(List<UserModel> users) {
    final normalizedUsername =
        widget.nickname?.replaceFirst('@', '').toLowerCase();
    return users.cast<UserModel?>().firstWhere(
      (user) {
        if (user == null || normalizedUsername == null) return false;
        return user.username?.toLowerCase() == normalizedUsername ||
            user.profileSlug.toLowerCase() == normalizedUsername;
      },
      orElse: () => null,
    );
  }
}

class _ProfileNotFound extends StatelessWidget {
  final String? username;

  const _ProfileNotFound({required this.username});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: colors.error),
          const SizedBox(height: 16),
          Text(
            'Пользователь @$username не найден',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('В кабинет'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final UserModel user;
  final bool isOwner;
  final ProfileSection section;
  final VoidCallback onEdit;
  final VoidCallback onDashboard;
  final VoidCallback? onReport;

  const _ProfileHero({
    required this.user,
    required this.isOwner,
    required this.section,
    required this.onEdit,
    required this.onDashboard,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          _UserAvatar(user: user, color: colors.primary, radius: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.alternate_email_rounded,
                      label: user.displayUsername,
                    ),
                    _InfoChip(
                      icon: user.isDriver
                          ? Icons.inventory_2_rounded
                          : Icons.manage_accounts_rounded,
                      label: user.displayRole,
                    ),
                    _InfoChip(
                      icon: Icons.star_rounded,
                      label: user.ratingCount == 0
                          ? 'Нет оценок'
                          : '${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                    ),
                    _InfoChip(icon: section.icon, label: section.label),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onDashboard,
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Рабочий стол'),
              ),
              if (isOwner)
                FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Редактировать'),
                ),
              if (!isOwner && onReport != null)
                OutlinedButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Пожаловаться'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  final UserModel profile;
  final ProfileSection selected;

  const _ProfileTabs({required this.profile, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProfileSection.values.map((section) {
        final isSelected = section == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(
            '/profile/${profile.profileSlug}/${section.path}',
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : colors.surfaceContainerHighest.withOpacity(0.56),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  section.icon,
                  size: 18,
                  color: isSelected ? Colors.white : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  section.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProfileAccountSection extends StatelessWidget {
  final UserModel profileUser;
  final UserModel? currentUser;
  final bool isOwner;
  final bool isEditing;
  final bool isLoading;
  final bool isRating;
  final int? selectedScore;
  final XFile? selectedAvatar;
  final TextEditingController nameController;
  final TextEditingController aboutController;
  final TextEditingController carController;
  final VoidCallback onEdit;
  final VoidCallback onPickAvatar;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final ValueChanged<int>? onRate;

  const _ProfileAccountSection({
    required this.profileUser,
    required this.currentUser,
    required this.isOwner,
    required this.isEditing,
    required this.isLoading,
    required this.isRating,
    required this.selectedScore,
    required this.selectedAvatar,
    required this.nameController,
    required this.aboutController,
    required this.carController,
    required this.onEdit,
    required this.onPickAvatar,
    required this.onCancel,
    required this.onSave,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final left = _ProfilePanel(
      icon: Icons.person_outline_rounded,
      title: isOwner ? 'Ваш профиль' : 'Карточка пользователя',
      child: isEditing && isOwner ? _buildEditor(context) : _buildInfo(context),
    );
    final right = _ProfilePanel(
      icon: Icons.workspace_premium_outlined,
      title: 'Репутация и доступ',
      child: _buildReputation(context),
    );

    if (compact) {
      return Column(children: [left, const SizedBox(height: 14), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: left),
        const SizedBox(width: 14),
        Expanded(flex: 5, child: right),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      children: [
        _ProfileDataRow(label: 'ID', value: profileUser.uid.substring(0, 8)),
        _ProfileDataRow(label: 'Логин', value: profileUser.displayUsername),
        _ProfileDataRow(label: 'E-mail', value: profileUser.email),
        _ProfileDataRow(
          label: 'Роль',
          value: profileUser.displayRole,
        ),
        if (profileUser.isDriver)
          _ProfileDataRow(
            label: 'Транспорт',
            value: profileUser.car?.isNotEmpty == true
                ? profileUser.car!
                : 'Не указан',
          ),
        _ProfileDataRow(
          label: 'О себе',
          value: profileUser.aboutMe?.isNotEmpty == true
              ? profileUser.aboutMe!
              : 'Информация не указана',
        ),
        if (isOwner) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Изменить данные'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Имя / название'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onPickAvatar,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(
            selectedAvatar == null
                ? 'Выбрать фото из файлов'
                : 'Выбрано: ${selectedAvatar!.name}',
          ),
        ),
        if (selectedAvatar != null) ...[
          const SizedBox(height: 12),
          _SelectedAvatarPreview(file: selectedAvatar!),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: aboutController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'О себе'),
        ),
        if (profileUser.isDriver) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: carController,
            decoration: const InputDecoration(labelText: 'Бригада / транспорт'),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isLoading ? null : onCancel,
              child: const Text('Отмена'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onSave,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReputation(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.tertiary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.tertiary.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: colors.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  profileUser.ratingCount == 0
                      ? 'Пока нет оценок'
                      : '${profileUser.rating.toStringAsFixed(1)} из 5 · ${profileUser.ratingCount} оценок',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _RatingStars(
                value: profileUser.rating.round().clamp(0, 5).toInt(),
              ),
            ],
          ),
        ),
        if (!isOwner && currentUser != null) ...[
          const SizedBox(height: 18),
          Text(
            'Оценить пользователя',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final score = index + 1;
              final selected =
                  (selectedScore ?? profileUser.rating.round()) >= score;
              return IconButton(
                tooltip: '$score',
                onPressed:
                    isRating || onRate == null ? null : () => onRate!(score),
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: colors.tertiary,
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 18),
        _ProfileDataRow(
          label: 'Статус',
          value: isOwner ? 'Это ваш аккаунт' : 'Публичный профиль',
        ),
        _ProfileDataRow(
          label: 'Синхронизация',
          value: 'Firebase Auth, Firestore и Storage',
        ),
      ],
    );
  }
}

class _ProfilePeopleSection extends StatelessWidget {
  final String title;
  final List<UserModel> users;
  final UserModel? currentUser;
  final bool Function(UserModel user) filter;
  final bool showVehicle;

  const _ProfilePeopleSection({
    required this.title,
    required this.users,
    required this.currentUser,
    required this.filter,
    this.showVehicle = false,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = users.where(filter).toList();
    return _ProfilePanel(
      icon: showVehicle
          ? Icons.local_shipping_outlined
          : Icons.people_alt_outlined,
      title: title,
      child: filtered.isEmpty
          ? const _ProfileEmpty(
              icon: Icons.people_outline_rounded,
              title: 'Список пуст',
              message: 'Когда пользователи появятся, они будут здесь.',
            )
          : Column(
              children: filtered
                  .map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProfilePersonTile(
                        user: user,
                        isCurrent: currentUser?.uid == user.uid,
                        showVehicle: showVehicle,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ProfileCargosSection extends StatelessWidget {
  final UserModel profileUser;
  final UserModel? currentUser;
  final bool favoritesOnly;

  const _ProfileCargosSection({
    required this.profileUser,
    required this.currentUser,
    required this.favoritesOnly,
  });

  @override
  Widget build(BuildContext context) {
    if (favoritesOnly && currentUser?.uid != profileUser.uid) {
      return const _ProfilePanel(
        icon: Icons.lock_outline_rounded,
        title: 'Отмеченные',
        child: _ProfileEmpty(
          icon: Icons.lock_outline_rounded,
          title: 'Раздел приватный',
          message: 'Отмеченные грузы доступны только владельцу аккаунта.',
        ),
      );
    }

    return StreamBuilder<List<CargoModel>>(
      stream: CargoRepository.instance.watchAllCargos(),
      builder: (context, cargoSnapshot) {
        if (cargoSnapshot.connectionState == ConnectionState.waiting &&
            !cargoSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allCargos = cargoSnapshot.data ?? const <CargoModel>[];
        if (!favoritesOnly) {
          final cargos = allCargos.where((cargo) {
            return cargo.ownerId == profileUser.uid ||
                cargo.driverId == profileUser.uid;
          }).toList();
          return _ProfileCargoList(
            title: 'Грузы пользователя',
            cargos: cargos,
            emptyMessage: 'У пользователя пока нет связанных грузов.',
          );
        }

        return StreamBuilder<Set<String>>(
          stream:
              UserRepository.instance.watchFavoriteCargoIds(profileUser.uid),
          builder: (context, favoriteSnapshot) {
            final ids = favoriteSnapshot.data ?? const <String>{};
            final cargos =
                allCargos.where((cargo) => ids.contains(cargo.id)).toList();
            return _ProfileCargoList(
              title: 'Отмеченные грузы',
              cargos: cargos,
              emptyMessage: 'Сохраненных звездочкой грузов пока нет.',
            );
          },
        );
      },
    );
  }
}

class _ProfileSettingsSection extends StatelessWidget {
  final UserModel profileUser;
  final bool isOwner;

  const _ProfileSettingsSection({
    required this.profileUser,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOwner) {
      return const _ProfilePanel(
        icon: Icons.lock_outline_rounded,
        title: 'Настройки',
        child: _ProfileEmpty(
          icon: Icons.lock_outline_rounded,
          title: 'Раздел приватный',
          message: 'Настройки доступны только владельцу аккаунта.',
        ),
      );
    }

    final items = [
      _SettingsItem(
        icon: Icons.alternate_email_rounded,
        title: 'Логин',
        value: profileUser.displayUsername,
      ),
      _SettingsItem(
        icon: Icons.email_outlined,
        title: 'E-mail',
        value: profileUser.email,
      ),
      _SettingsItem(
        icon: Icons.privacy_tip_outlined,
        title: 'Приватность',
        value: 'Профиль публичный, отмеченные грузы приватные',
      ),
      const _SettingsItem(
        icon: Icons.verified_user_outlined,
        title: 'Безопасность',
        value: 'Аккаунт защищен Firebase Auth',
      ),
    ];

    return _ProfilePanel(
      icon: Icons.tune_rounded,
      title: 'Настройки аккаунта',
      child: Column(
        children: [
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: item,
            ),
          ),
          _SettingsItem(
            icon: Icons.mark_email_read_rounded,
            title: 'Статус E-mail',
            value: 'Подтверждён',
          ),
          const SizedBox(height: 10),
          _SecurityActionTile(
            icon: Icons.lock_reset_rounded,
            title: 'Сброс пароля',
            value: 'Отправить ссылку восстановления пароля',
            onPressed: () => AuthRepository.instance
                .sendPasswordResetEmail(profileUser.email),
            successMessage: 'Письмо для сброса пароля отправлено',
          ),
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ProfilePanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ProfileDataRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _ProfilePersonTile extends StatelessWidget {
  final UserModel user;
  final bool isCurrent;
  final bool showVehicle;

  const _ProfilePersonTile({
    required this.user,
    required this.isCurrent,
    required this.showVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final roleColor = user.isDriver ? colors.tertiary : colors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go('/profile/${user.profileSlug}/cabinet'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.36),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            _UserAvatar(user: user, color: roleColor, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        _StatusPill(label: 'Вы', color: colors.secondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showVehicle
                        ? (user.car?.isNotEmpty == true
                            ? user.car!
                            : 'Транспорт не указан')
                        : '${user.displayUsername} · ${user.displayRole}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _RatingStars(value: user.rating.round().clamp(0, 5).toInt()),
          ],
        ),
      ),
    );
  }
}

class _ProfileCargoList extends StatelessWidget {
  final String title;
  final List<CargoModel> cargos;
  final String emptyMessage;

  const _ProfileCargoList({
    required this.title,
    required this.cargos,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfilePanel(
      icon: Icons.inventory_2_outlined,
      title: '$title (${cargos.length})',
      child: cargos.isEmpty
          ? _ProfileEmpty(
              icon: Icons.inventory_2_outlined,
              title: 'Грузов нет',
              message: emptyMessage,
            )
          : Column(
              children: cargos
                  .map(
                    (cargo) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProfileCargoTile(cargo: cargo),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ProfileCargoTile extends StatelessWidget {
  final CargoModel cargo;

  const _ProfileCargoTile({required this.cargo});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(cargo.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: statusColor),
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
                const SizedBox(height: 4),
                Text(
                  '${cargo.from} -> ${cargo.to}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(label: cargo.status, color: statusColor),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  value,
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
    );
  }
}

class _SecurityActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final Future<void> Function() onPressed;
  final String successMessage;

  const _SecurityActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onPressed,
    required this.successMessage,
  });

  @override
  State<_SecurityActionTile> createState() => _SecurityActionTileState();
}

class _SecurityActionTileState extends State<_SecurityActionTile> {
  bool _isLoading = false;

  Future<void> _run() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.successMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось выполнить действие: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.value,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _isLoading ? null : _run,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Выполнить'),
          ),
        ],
      ),
    );
  }
}

class _SelectedAvatarPreview extends StatelessWidget {
  final XFile file;

  const _SelectedAvatarPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.primary.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: snapshot.hasData
                      ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                      : const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Фото выбрано. Нажмите "Сохранить", чтобы загрузить его в профиль.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ProfileEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
