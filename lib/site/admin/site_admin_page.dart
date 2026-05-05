part of '../../main_site.dart';

class SiteAdminGate extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteAdminGate({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthRepository.instance.watchCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SiteLoadingScreen(
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        }

        if (snapshot.hasError) {
          return SiteErrorScreen(
            title: 'Ошибка проверки доступа',
            message: snapshot.error.toString(),
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return SiteRouteRedirect(
            location: '/auth',
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        }

        if (!user.isAdmin) {
          return SiteAccessDeniedScreen(
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        }

        return SiteAdminPage(
          user: user,
          isDark: isDark,
          onToggleTheme: onToggleTheme,
        );
      },
    );
  }
}

class SiteAdminPage extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteAdminPage({
    super.key,
    required this.user,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserRepository.instance.watchAllUsers(),
      builder: (context, userSnapshot) {
        return StreamBuilder<List<CargoModel>>(
          stream: CargoRepository.instance.watchAllCargos(),
          builder: (context, cargoSnapshot) {
            final users = userSnapshot.data ?? const <UserModel>[];
            final cargos = cargoSnapshot.data ?? const <CargoModel>[];
            final error = userSnapshot.error ?? cargoSnapshot.error;

            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  tooltip: 'На главную',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/'),
                ),
                title: const Text('Админ-панель Logist App'),
                actions: [
                  ThemeIconButton(isDark: isDark, onPressed: onToggleTheme),
                  IconButton(
                    tooltip: 'Выйти',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: AuthRepository.instance.signOut,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: error != null
                  ? Center(
                      child: _StatePanel(
                        icon: Icons.cloud_off_rounded,
                        title: 'Данные недоступны',
                        message: error.toString(),
                      ),
                    )
                  : userSnapshot.connectionState == ConnectionState.waiting &&
                          !userSnapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : AdminSection(
                          user: user,
                          users: users,
                          cargos: cargos,
                        ),
            );
          },
        );
      },
    );
  }
}

class SiteAccessDeniedScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteAccessDeniedScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступ закрыт'),
        actions: [
          ThemeIconButton(isDark: isDark, onPressed: onToggleTheme),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: _StatePanel(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Нужен админ-аккаунт',
          message:
              'Этот раздел доступен только отдельным аккаунтам администраторов.',
          actionLabel: 'Вернуться в кабинет',
          onAction: () => context.go('/dashboard'),
        ),
      ),
    );
  }
}
