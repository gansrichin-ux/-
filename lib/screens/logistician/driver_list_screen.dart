import 'package:flutter/material.dart';
import '../../repositories/cargo_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/cargo_model.dart';
import '../../models/user_model.dart';

class DriverListScreen extends StatelessWidget {
  const DriverListScreen({super.key});

  void _showAssignCargoModal(
    BuildContext context,
    String driverId,
    String driverName,
  ) {
    final ownerId = AuthRepository.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Назначить груз: $driverName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<CargoModel>>(
                stream: ownerId == null
                    ? Stream.value(const <CargoModel>[])
                    : CargoRepository.instance.watchNewCargos(ownerId: ownerId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Ошибка'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cargos = snapshot.data ?? [];
                  if (cargos.isEmpty) {
                    return const Center(child: Text('Нет новых грузов'));
                  }

                  return ListView.builder(
                    itemCount: cargos.length,
                    itemBuilder: (context, index) {
                      final cargo = cargos[index];
                      return ListTile(
                        title: Text(cargo.title),
                        subtitle: Text('${cargo.from} ➔ ${cargo.to}'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await CargoRepository.instance.assignDriver(
                              cargoId: cargo.id,
                              driverId: driverId,
                              driverName: driverName,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Назначить'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: StreamBuilder<List<UserModel>>(
        stream: UserRepository.instance.watchDrivers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = snapshot.data ?? [];
          if (drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Водители не найдены',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Всего пользователей в базе: (проверьте логи)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF3B82F6,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              driver.car ?? 'Нет машины',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.assignment_rounded),
                        color: const Color(0xFF3B82F6),
                        tooltip: 'Назначить груз',
                        onPressed: () => _showAssignCargoModal(
                          context,
                          driver.uid,
                          driver.displayName,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
