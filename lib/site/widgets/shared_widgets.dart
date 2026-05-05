part of '../../main_site.dart';

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _PanelHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: colors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  final bool isDense;

  const _LogoMark({this.isDense = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = isDense ? 38.0 : 46.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.route_rounded, color: Colors.white, size: 24),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final UserModel user;
  final Color color;
  final double radius;

  const _UserAvatar({
    required this.user,
    required this.color,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final avatarUrl = user.avatarUrl?.trim();

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: color,
        child: avatarUrl?.isNotEmpty == true
            ? Image.network(
                avatarUrl!,
                key: ValueKey(avatarUrl),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) =>
                    _AvatarFallback(user: user),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: radius * 0.7,
                      height: radius * 0.7,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              )
            : _AvatarFallback(user: user),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final UserModel user;

  const _AvatarFallback({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _userInitial(user.displayName),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  final UserModel user;
  final Color color;
  final VoidCallback? onTap;

  const _UserBadge({required this.user, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            _UserAvatar(user: user, color: color, radius: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${user.displayUsername} · ${user.displayRole}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
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

class _ExchangeRatePanel extends StatefulWidget {
  const _ExchangeRatePanel();

  @override
  State<_ExchangeRatePanel> createState() => _ExchangeRatePanelState();
}

class _ExchangeRatePanelState extends State<_ExchangeRatePanel> {
  ExchangeRates? _rates;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRates();
    _timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadRates(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadRates() async {
    try {
      final rates = await ExchangeRateService.instance.fetchLatestRates();
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rub = _findRate('RUB');
    final usd = _findRate('USD');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange_rounded,
                  size: 17, color: colors.primary),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Курс валют',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'Обновить курс',
                onPressed: _loadRates,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_rates == null && _error == null)
            const LinearProgressIndicator(minHeight: 3)
          else if (_error != null)
            Text(
              'Курсы временно недоступны',
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            if (usd != null) _RateLine(label: '1 USD', value: usd.kztRate),
            if (rub != null) _RateLine(label: '1 RUB', value: rub.kztRate),
            const SizedBox(height: 4),
            Text(
              'Обновлено ${DateFormat('HH:mm').format(_rates!.updatedAt)}',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  CurrencyRate? _findRate(String code) {
    final rates = _rates;
    if (rates == null) return null;
    return rates.currencies.cast<CurrencyRate?>().firstWhere(
          (rate) => rate?.code == code,
          orElse: () => null,
        );
  }
}

class _RateLine extends StatelessWidget {
  final String label;
  final double value;

  const _RateLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          Text(
            '${value.toStringAsFixed(value >= 100 ? 0 : 2)} ₸',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ThemeIconButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const ThemeIconButton({
    super.key,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isDark ? 'Светлая тема' : 'Темная тема',
      onPressed: onPressed,
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
    );
  }
}

class _RouteGridPainter extends CustomPainter {
  final Color lineColor;
  final Color nodeColor;

  const _RouteGridPainter({required this.lineColor, required this.nodeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final routePaint = Paint()
      ..color = nodeColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final nodePaint = Paint()..color = nodeColor;

    for (var x = 0.0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.72)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.42,
        size.width * 0.52,
        size.height * 0.82,
        size.width * 0.72,
        size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width * 0.9,
        size.height * 0.34,
        size.width * 0.94,
        size.height * 0.2,
      );

    canvas.drawPath(path, routePaint);

    final nodes = [
      Offset(size.width * 0.14, size.height * 0.72),
      Offset(size.width * 0.48, size.height * 0.66),
      Offset(size.width * 0.72, size.height * 0.44),
      Offset(size.width * 0.94, size.height * 0.2),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 7, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.nodeColor != nodeColor;
  }
}
