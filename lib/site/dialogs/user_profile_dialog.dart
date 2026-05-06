part of '../../main_site.dart';

class UserProfileDialog extends StatefulWidget {
  final UserModel profile;
  final UserModel currentUser;
  final Future<void> Function(int score) onRate;

  const UserProfileDialog({
    super.key,
    required this.profile,
    required this.currentUser,
    required this.onRate,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  var _isRating = false;
  int? _selectedScore;

  bool get _isMe => widget.profile.uid == widget.currentUser.uid;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final roleColor =
        widget.profile.isCarrier ? colors.tertiary : colors.primary;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _UserAvatar(
                    user: widget.profile,
                    color: roleColor,
                    radius: 30,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.profile.displayUsername,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: widget.profile.isCarrier
                        ? Icons.inventory_2_rounded
                        : Icons.manage_accounts_rounded,
                    label: widget.profile.displayRole,
                  ),
                  _InfoChip(
                    icon: Icons.email_outlined,
                    label: widget.profile.email,
                  ),
                  if (widget.profile.car?.isNotEmpty == true)
                    _InfoChip(
                      icon: Icons.local_shipping_outlined,
                      label: widget.profile.car!,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: colors.tertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profile.ratingCount == 0
                                ? 'Пока нет оценок'
                                : '${widget.profile.rating.toStringAsFixed(1)} из 5',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${widget.profile.ratingCount} оценок',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RatingStars(value: widget.profile.rating.round()),
                  ],
                ),
              ),
              if (!_isMe) ...[
                const SizedBox(height: 18),
                Text(
                  'Оценить пользователя',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    final score = index + 1;
                    final selected = (_selectedScore ?? 0) >= score;
                    return IconButton(
                      tooltip: '$score',
                      onPressed: _isRating
                          ? null
                          : () async {
                              setState(() {
                                _selectedScore = score;
                                _isRating = true;
                              });
                              try {
                                await widget.onRate(score);
                                if (context.mounted) Navigator.pop(context);
                              } finally {
                                if (mounted) setState(() => _isRating = false);
                              }
                            },
                      icon: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: colors.tertiary,
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final int value;

  const _RatingStars({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < value ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.tertiary,
        );
      }),
    );
  }
}
