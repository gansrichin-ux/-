part of '../../main_site.dart';

class UsersSection extends StatefulWidget {
  final List<UserModel> users;
  final UserModel currentUser;
  final UserModel user;
  final Future<void> Function(UserModel user) onOpenProfile;
  final Future<void> Function(UserModel user) onOpenChat;

  const UsersSection({
    super.key,
    required this.users,
    required this.currentUser,
    required this.user,
    required this.onOpenProfile,
    required this.onOpenChat,
  });

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  var _query = '';
  var _role = 'all';

  @override
  Widget build(BuildContext context) {
    final users = widget.users.where((user) {
      if (_role != 'all' && user.role != _role) return false;
      final query = _query.trim().toLowerCase().replaceFirst('@', '');
      if (query.isEmpty) return true;
      return user.displayName.toLowerCase().contains(query) ||
          user.displayUsername.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final search = TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Найти пользователя по имени, email или @username',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              );
              final filter = SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('Все')),
                  ButtonSegment(value: 'logistician', label: Text('Логисты')),
                  ButtonSegment(value: 'driver', label: Text('Водители')),
                ],
                selected: {_role},
                showSelectedIcon: false,
                onSelectionChanged: (value) {
                  setState(() => _role = value.first);
                },
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 12), filter],
                );
              }

              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 14),
                  filter,
                ],
              );
            },
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? const Center(
                  child: _StatePanel(
                    icon: Icons.people_outline_rounded,
                    title: 'Пользователи не найдены',
                    message: 'Измените поиск или фильтр роли.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 96),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserDirectoryCard(
                      user: user,
                      isCurrentUser: user.uid == widget.currentUser.uid,
                      onOpen: () => widget.onOpenProfile(user),
                      onChat: user.uid == widget.currentUser.uid
                          ? null
                          : () => widget.onOpenChat(user),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _UserDirectoryCard extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback onOpen;
  final VoidCallback? onChat;

  const _UserDirectoryCard({
    required this.user,
    required this.isCurrentUser,
    required this.onOpen,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final roleColor = user.isDriver ? colors.tertiary : colors.primary;

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _UserAvatar(user: user, color: roleColor, radius: 24),
              const SizedBox(width: 14),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          _StatusPill(label: 'Вы', color: colors.secondary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
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
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (onChat != null)
                IconButton(
                  tooltip: 'Написать',
                  icon: const Icon(Icons.forum_outlined),
                  onPressed: onChat,
                ),
              IconButton(
                tooltip: 'Открыть профиль',
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
