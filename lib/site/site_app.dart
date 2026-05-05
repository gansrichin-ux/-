part of '../main_site.dart';

class LogistSiteApp extends StatefulWidget {
  final bool firebaseReady;
  final Object? firebaseError;
  final String? initialTheme;

  const LogistSiteApp({
    super.key,
    required this.firebaseReady,
    this.firebaseError,
    this.initialTheme,
  });

  @override
  State<LogistSiteApp> createState() => _LogistSiteAppState();
}

class _LogistSiteAppState extends State<LogistSiteApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _initialLocation = _currentLocation();

  @override
  void initState() {
    super.initState();
    final savedTheme = widget.initialTheme;
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    }
  }

  bool get _isDark {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system && brightness == Brightness.dark);
  }

  void _toggleTheme() async {
    setState(() {
      _initialLocation = _currentLocation();
      _themeMode = _isDark ? ThemeMode.light : ThemeMode.dark;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('site_theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  static String _currentLocation() {
    final uri = Uri.base;
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '$path$query';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Logist App Site',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      routerConfig: createSiteRouter(
        initialLocation: _initialLocation,
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
      builder: (context, child) {
        if (!widget.firebaseReady) {
          return FirebaseSetupScreen(
            isDark: _isDark,
            onToggleTheme: _toggleTheme,
            error: widget.firebaseError,
          );
        }
        return child ?? const SizedBox();
      },
    );
  }
}

