import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/location_providers.dart';

class LocationPermissionWidget extends ConsumerWidget {
  const LocationPermissionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_off_rounded,
                  color: Colors.orange.withOpacity(0.8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Требуется разрешение на геолокацию',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Для отслеживания вашего местоположения необходимо предоставить доступ к GPS. Это поможет логистам видеть ваше местоположение в реальном времени.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(locationPermissionProvider.notifier).requestPermission();
                    },
                    icon: const Icon(Icons.location_on_rounded),
                    label: const Text('Разрешить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
