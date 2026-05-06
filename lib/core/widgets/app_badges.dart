import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  final String? url;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.url,
    required this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colors.primary;

    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url!),
        backgroundColor: colors.surfaceContainerHighest,
      );
    }

    final String initials = fallbackText.isNotEmpty 
        ? fallbackText.substring(0, 1).toUpperCase() 
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class RouteBadge extends StatelessWidget {
  final String from;
  final String to;
  final double fontSize;

  const RouteBadge({
    super.key,
    required this.from,
    required this.to,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            from,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: fontSize + 4,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: fontSize + 2,
            color: colors.primary.withOpacity(0.5),
          ),
        ),
        Flexible(
          child: Text(
            to,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: fontSize + 4,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class PriceBadge extends StatelessWidget {
  final double price;
  final String currency;

  const PriceBadge({
    super.key,
    required this.price,
    this.currency = '₸',
  });

  @override
  Widget build(BuildContext context) {
    // Format price with spaces (e.g., 500 000)
    final formattedPrice = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$formattedPrice $currency',
        style: AppTextStyles.titleSmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class TruckBodyTypeBadge extends StatelessWidget {
  final String bodyType;

  const TruckBodyTypeBadge({
    super.key,
    required this.bodyType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            bodyType, // We will translate this later
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
