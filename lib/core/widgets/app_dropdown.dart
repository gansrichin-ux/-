import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_radius.dart';

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? errorText;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.label),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          style: AppTextStyles.bodyLarge,
          dropdownColor: Theme.of(context).cardColor,
          borderRadius: AppRadius.mediumRadius,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
