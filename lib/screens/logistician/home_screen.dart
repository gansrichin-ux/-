import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'cargo_list_screen.dart';
import 'driver_list_screen.dart';
import 'client_list_screen.dart';
import 'analytics_screen.dart';
import 'notification_screen.dart';
import '../settings_screen.dart';
import '../../core/providers/notification_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _pages = [
    DashboardScreen(),
    CargoListScreen(),
    DriverListScreen(),
    ClientListScreen(),
    AnalyticsScreen(),
  ];

  static const _labels = [
    'Р“Р»Р°РІРЅР°СЏ',
    'Р“СЂСѓР·С‹',
    'Р’РѕРґРёС‚РµР»Рё',
    'РљР»РёРµРЅС‚С‹',
    'РњРѕСЏ\nСЃС‚Р°С‚РёСЃС‚РёРєР°',
  ];
  static const _titles = [
    'Р“Р»Р°РІРЅР°СЏ',
    'Р“СЂСѓР·С‹',
    'Р’РѕРґРёС‚РµР»Рё',
    'РљР»РёРµРЅС‚С‹',
    'РњРѕСЏ СЃС‚Р°С‚РёСЃС‚РёРєР°',
  ];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.local_shipping_rounded,
    Icons.people_rounded,
    Icons.person_rounded,
    Icons.analytics_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          // Notification button with badge
          Consumer(
            builder: (context, ref, child) {
              final unreadCountAsync = ref.watch(unreadCountProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      return unreadCountAsync.when(
                        data: (count) => count > 0
                            ? Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
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
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          height: 76,
          elevation: 0,
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF3B82F6).withOpacity(0.18),
          destinations: List.generate(
            _labels.length,
            (i) => NavigationDestination(
              icon: Icon(_icons[i], color: const Color(0xFF94A3B8)),
              selectedIcon: Icon(_icons[i], color: Colors.white),
              label: _labels[i],
            ),
          ),
        ),
      ),
    );
  }
}
