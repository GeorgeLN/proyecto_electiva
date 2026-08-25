import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/signup_screen.dart';
import '../../features/home/presentation/view/home_screen.dart';
import '../../features/plant_detail/presentation/view/plant_detail_screen.dart';
import '../../features/plant_form/presentation/view/plant_form_screen.dart';
import '../../features/profile/presentation/view/profile_screen.dart';
import 'go_router_refresh_stream.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = ref.read(currentUserProvider) != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
        path: '/plants/add',
        builder: (context, state) => const PlantFormScreen(),
      ),
      GoRoute(
        path: '/plants/:id',
        builder: (context, state) => PlantDetailScreen(plantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plants/:id/edit',
        builder: (context, state) => PlantFormScreen(plantId: state.pathParameters['id']!),
      ),
    ],
  );
});
