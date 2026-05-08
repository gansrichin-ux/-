part of '../main_site.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createSiteRouter({
  required String initialLocation,
  required bool isDark,
  required VoidCallback onToggleTheme,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => SiteLandingPage(
          isDark: isDark,
          onToggleTheme: onToggleTheme,
        ),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => SiteAuthGate(
          isDark: isDark,
          onToggleTheme: onToggleTheme,
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => SiteDashboardGate(
          workspaceSlug: null,
          isDark: isDark,
          onToggleTheme: onToggleTheme,
        ),
      ),
      GoRoute(
        path: '/dashboard/:workspace',
        builder: (context, state) => SiteDashboardGate(
          workspaceSlug: state.pathParameters['workspace'],
          isDark: isDark,
          onToggleTheme: onToggleTheme,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => SiteAdminGate(
          isDark: isDark,
          onToggleTheme: onToggleTheme,
        ),
      ),
      GoRoute(
        path: '/profile/:nickname',
        builder: (context, state) {
          final nickname = state.pathParameters['nickname'];
          return UserProfilePage(
            nickname: nickname,
            section: ProfileSection.account,
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        },
      ),
      GoRoute(
        path: '/profile/:nickname/:section',
        builder: (context, state) {
          final nickname = state.pathParameters['nickname'];
          final section = ProfileSection.fromPath(
            state.pathParameters['section'],
          );
          return UserProfilePage(
            nickname: nickname,
            section: section,
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        },
      ),
      GoRoute(
        path: '/user@:nickname',
        builder: (context, state) {
          final nickname = state.pathParameters['nickname'];
          return SiteRouteRedirect(
            location: '/profile/$nickname/${ProfileSection.account.path}',
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        },
      ),
      GoRoute(
        path: '/user/:nickname',
        builder: (context, state) {
          final nickname = state.pathParameters['nickname'];
          return SiteRouteRedirect(
            location: '/profile/$nickname/${ProfileSection.account.path}',
            isDark: isDark,
            onToggleTheme: onToggleTheme,
          );
        },
      ),
    ],
  );
}
