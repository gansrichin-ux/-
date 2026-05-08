import 'package:flutter/material.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_text_styles.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final titleStyle = AppTextStyles.display.copyWith(
      fontSize: isMobile ? 30 : 28,
      height: 1.08,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: AppTextStyles.bodyMedium),
                ],
                if (trailing != null) ...[
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerLeft, child: trailing!),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: titleStyle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: AppTextStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing!,
                ],
              ],
            ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium,
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
