import 'package:flutter/material.dart';
import '../config/cargo_statuses.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';
import 'app_badges.dart';
import 'app_status_badge.dart';

class CargoStatusBadge extends StatelessWidget {
  final String status;
  // This will be replaced with real localization and status mapping later
  
  const CargoStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color statusColor;
    String displayStatus = status;

    // Temporary basic mapping, will be replaced by cargo_statuses.dart
    if (status.toLowerCase() == 'published' || status == CargoStatus.published) {
      statusColor = colors.primary;
      displayStatus = 'Опубликован';
    } else if (status.toLowerCase() == 'in_transit' || status == 'В пути') {
      statusColor = colors.tertiary;
      displayStatus = 'В пути';
    } else if (status.toLowerCase() == 'delivered' || status == 'Доставлено') {
      statusColor = colors.secondary;
      displayStatus = 'Доставлено';
    } else {
      statusColor = colors.onSurfaceVariant;
    }

    return AppStatusBadge(
      label: displayStatus,
      color: statusColor,
    );
  }
}

class CargoCard extends StatelessWidget {
  final String title;
  final String from;
  final String to;
  final String status;
  final double? price;
  final String? bodyType;
  final DateTime? date;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const CargoCard({
    super.key,
    required this.title,
    required this.from,
    required this.to,
    required this.status,
    this.price,
    this.bodyType,
    this.date,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CargoStatusBadge(status: status),
              if (date != null)
                Text(
                  '${date!.day}.${date!.month}.${date!.year}',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          RouteBadge(from: from, to: to),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (bodyType != null) TruckBodyTypeBadge(bodyType: bodyType!),
              if (bodyType == null) const SizedBox(),
              if (price != null) PriceBadge(price: price!),
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
