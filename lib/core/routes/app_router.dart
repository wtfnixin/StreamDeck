import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/pages/pairing_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/launcher/presentation/pages/apps_launcher_page.dart';
import '../../features/launcher/presentation/pages/websites_launcher_page.dart';
import '../../features/workspace/presentation/pages/workspaces_page.dart';
import '../../features/gestures/presentation/pages/gesture_pad_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/dashboard/presentation/pages/stream_deck_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const PairingPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/apps',
        builder: (context, state) => const AppsLauncherPage(),
      ),
      GoRoute(
        path: '/websites',
        builder: (context, state) => const WebsitesLauncherPage(),
      ),
      GoRoute(
        path: '/workspaces',
        builder: (context, state) => const WorkspacesPage(),
      ),
      GoRoute(
        path: '/gesture-pad',
        builder: (context, state) => const GesturePadPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/stream-deck',
        builder: (context, state) => const StreamDeckPage(),
      ),
    ],
  );
}
