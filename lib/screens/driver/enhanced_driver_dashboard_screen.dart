import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/location_providers.dart';
import '../../core/providers/cargo_providers.dart';
import '../../models/user_model.dart';
import '../../models/cargo_model.dart';
import '../../widgets/location_permission_widget.dart';
import '../../widgets/tracking_toggle_widget.dart';
import '../settings_screen.dart';

class EnhancedDriverDashboardScreen extends ConsumerStatefulWidget {
  const EnhancedDriverDashboardScreen({super.key});

  @override
  ConsumerState<EnhancedDriverDashboardScreen> createState() =>
      _EnhancedDriverDashboardScreenState();
}

class _EnhancedDriverDashboardScreenState
    extends ConsumerState<EnhancedDriverDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final locationPermission = ref.watch(locationPermissionProvider);
    final isTracking = ref.watch(locationTrackingProvider);
    final currentPosition = ref.watch(currentPositionProvider);

    return authState.when(
      authenticated: (userModel) => _buildBody(
        userModel,
        locationPermission,
        isTracking,
        currentPosition,
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      ),
      onError: (error) =>
          Scaffold(body: Center(child: Text('РћС€РёР±РєР°: $error'))),
      unauthenticated: () => const Scaffold(
          body: Center(child: Text('РќРµ Р°РІС‚РѕСЂРёР·РѕРІР°РЅ'))),
    );
  }

  Widget _buildBody(
    UserModel? user,
    LocationPermissionStatus permission,
    bool isTracking,
    AsyncValue<Position> position,
  ) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ РЅРµ РЅР°Р№РґРµРЅ')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('РџР°РЅРµР»СЊ РІРѕРґРёС‚РµР»СЏ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'РќР°СЃС‚СЂРѕР№РєРё',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(locationPermissionProvider);
        },
        child: CustomScrollView(
          slivers: [
            // User Info Card
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF3B82F6),
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            if (user.car?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.car!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Location Tracking Section
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'РћС‚СЃР»РµР¶РёРІР°РЅРёРµ РјРµСЃС‚РѕРїРѕР»РѕР¶РµРЅРёСЏ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TrackingToggleWidget(isTracking: isTracking),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (permission == LocationPermissionStatus.granted)
                        _buildLocationInfo(position)
                      else
                        const LocationPermissionWidget(),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Driver's Cargos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'РњРѕРё РіСЂСѓР·С‹',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
            ),

            Consumer(
              builder: (context, ref, child) {
                final driverCargos = ref.watch(driverCargosProvider(user.uid));

                return driverCargos.when(
                  data: (cargos) => _buildCargosList(cargos),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => const SliverToBoxAdapter(
                    child: Center(
                        child:
                            Text('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РіСЂСѓР·РѕРІ')),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(AsyncValue<Position> position) {
    return position.when(
      data: (pos) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'РўРµРєСѓС‰РµРµ РјРµСЃС‚РѕРїРѕР»РѕР¶РµРЅРёРµ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          ...[
            const SizedBox(height: 4),
            Text(
              'РўРѕС‡РЅРѕСЃС‚СЊ: В±${pos.accuracy.toStringAsFixed(0)}Рј',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(
          child: Text(
              'РћС€РёР±РєР° РѕРїСЂРµРґРµР»РµРЅРёСЏ РјРµСЃС‚РѕРїРѕР»РѕР¶РµРЅРёСЏ')),
    );
  }

  Widget _buildCargosList(List<CargoModel> cargos) {
    if (cargos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text('РЈ РІР°СЃ РїРѕРєР° РЅРµС‚ РіСЂСѓР·РѕРІ')),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final cargo = cargos[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: ListTile(
              title: Text(cargo.title),
              subtitle: Text('${cargo.from} в†’ ${cargo.to}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(cargo.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cargo.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed('/cargo-details', arguments: cargo.id);
              },
            ),
          ),
        );
      }, childCount: cargos.length),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'РќРѕРІС‹Р№':
        return const Color(0xFF22C55E);
      case 'Р’ РїСѓС‚Рё':
        return const Color(0xFF3B82F6);
      case 'Р”РѕСЃС‚Р°РІР»РµРЅ':
        return const Color(0xFF10B981);
      case 'РћС‚РјРµРЅРµРЅ':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }
}
