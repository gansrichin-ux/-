import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/location_providers.dart';

class TrackingToggleWidget extends ConsumerWidget {
  final bool isTracking;

  const TrackingToggleWidget({super.key, required this.isTracking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(locationTrackingProvider.notifier).toggleTracking();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isTracking ? const Color(0xFF22C55E) : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTracking ? const Color(0xFF22C55E) : const Color(0xFF64748B),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isTracking ? Icons.location_on_rounded : Icons.location_off_rounded,
                key: ValueKey(isTracking),
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isTracking ? 'Включено' : 'Выключено',
                key: ValueKey(isTracking),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
