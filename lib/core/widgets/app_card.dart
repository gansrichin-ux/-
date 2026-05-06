import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;
  final bool withBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevated = false,
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumRadius,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.cardColor,
        borderRadius: AppRadius.mediumRadius,
        border: withBorder ? Border.all(color: theme.dividerColor) : null,
        boxShadow: elevated ? AppShadows.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: content,
      ),
    );
  }
}
