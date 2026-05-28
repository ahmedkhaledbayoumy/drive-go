import 'package:go_router/go_router.dart';

// V1 — Authentication
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/profile_screen.dart';
import '../features/auth/settings_screen.dart';

// V2 — Marketplace Discovery
import '../features/discovery/home_screen.dart';
import '../features/discovery/search_screen.dart';
import '../features/discovery/favorites_screen.dart';

// V3 — Listings
import '../features/listings/car_details_screen.dart';
import '../features/listings/edit_listing_screen.dart';
import '../features/listings/my_listings_screen.dart';
import '../features/listings/owner_profile_screen.dart';
import '../features/listings/rent_my_car_screen.dart';

// V5 — History, Notifications, Reviews
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/notifications_screen.dart';
import '../features/history/screens/review_screen.dart';

// Shared
import '../features/shared/placeholder_screen.dart';
import '../features/welcome/welcome_screen.dart';

import 'auth_provider.dart';
import '../features/discovery/models/filter_state.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/welcome',
      refreshListenable: auth,
      redirect: (context, state) {
        final path = state.matchedLocation;
        final isWelcome = path == '/welcome';
        final isAuthRoute =
            ['/login', '/signup', '/forgot-password'].contains(path);

        const guestBlocked = [
          '/favorites',
          '/list-car',
          '/my-listings',
          '/history',
          '/notifications',
          '/booking',
          '/chat',
          '/payment',
          '/review',
        ];
        final isBlockedForGuest = guestBlocked.any((r) => path.startsWith(r));

        if (auth.isUnauthenticated && !isWelcome && !isAuthRoute) {
          return '/welcome';
        }
        if (auth.isGuest && isBlockedForGuest) {
          return '/login';
        }
        if (auth.isAuthenticated && (isWelcome || isAuthRoute)) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, __) => '/welcome'),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),

        // V1 — Authentication (real)
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
        GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

        // V2 — Marketplace Discovery (real)
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (_, s) => SearchScreen(
            initialFilters:
                s.extra is FilterState ? s.extra as FilterState : null,
          ),
        ),
        GoRoute(
            path: '/favorites', builder: (_, __) => const FavoritesScreen()),

        // V3 — Listings (real)
        GoRoute(
            path: '/car/:id',
            builder: (_, s) =>
                CarDetailsScreen(carId: s.pathParameters['id']!)),
        GoRoute(path: '/list-car', builder: (_, __) => const RentMyCarScreen()),
        GoRoute(
            path: '/my-listings', builder: (_, __) => const MyListingsScreen()),
        GoRoute(
            path: '/edit-listing/:id',
            builder: (_, s) =>
                EditListingScreen(carId: s.pathParameters['id']!)),
        GoRoute(
            path: '/owner/:id',
            builder: (_, s) =>
                OwnerProfileScreen(ownerId: s.pathParameters['id']!)),

        // V4 — Booking, Chat, Mock Payment (placeholders for now)
        GoRoute(
            path: '/booking/:id',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Booking Details', verticalOwner: 'V4 — Booking')),
        GoRoute(
            path: '/chat/:bookingId',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Chat', verticalOwner: 'V4 — Booking')),
        GoRoute(
            path: '/payment/:bookingId',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Mock Payment', verticalOwner: 'V4 — Booking')),

        // V5 — History, Notifications, Reviews (real)
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen()),
        GoRoute(
            path: '/review/:bookingId',
            builder: (_, s) =>
                ReviewScreen(bookingId: s.pathParameters['bookingId']!)),
      ],
    );
  }
}
