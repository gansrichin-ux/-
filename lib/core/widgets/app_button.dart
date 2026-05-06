import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost, outlined }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? side;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = colors.primary;
        foregroundColor = colors.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = colors.surfaceContainerHighest;
        foregroundColor = colors.onSurface;
        break;
      case AppButtonVariant.danger:
        backgroundColor = colors.error;
        foregroundColor = colors.onError;
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        break;
      case AppButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.onSurface;
        side = BorderSide(color: colors.outline);
        break;
    }

    if (onPressed == null) {
      backgroundColor = colors.surfaceContainerHighest.withOpacity(0.5);
      foregroundColor = colors.onSurfaceVariant.withOpacity(0.5);
      if (variant == AppButtonVariant.outlined) {
        side = BorderSide(color: colors.outline.withOpacity(0.5));
      }
    }

    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTextStyles.button.copyWith(color: foregroundColor),
        ),
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mediumRadius,
        side: side ?? BorderSide.none,
      ),
      minimumSize: const Size(44, 44),
    );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonContent,
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    
    return button;
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double size;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.ghost,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color iconColor = color ?? colors.onSurfaceVariant;
    Color? bgColor;

    if (variant == AppButtonVariant.primary) {
      bgColor = colors.primary;
      iconColor = colors.onPrimary;
    } else if (variant == AppButtonVariant.secondary) {
      bgColor = colors.surfaceContainerHighest;
      iconColor = colors.onSurface;
    }

    final btn = IconButton(
      icon: Icon(icon, size: size, color: iconColor),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
        minimumSize: const Size(44, 44),
      ),
    );
    
    return btn;
  }
}
