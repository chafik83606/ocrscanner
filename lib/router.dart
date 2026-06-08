import 'package:go_router/go_router.dart';

import 'screens/home/home_screen.dart';
import 'screens/camera/camera_screen.dart';
import 'screens/result/result_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/premium/premium_screen.dart';
import 'models/scan_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/camera', builder: (_, __) => const CameraScreen()),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final scan = state.extra as ScanModel?;
        return ResultScreen(scan: scan);
      },
    ),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
  ],
);
