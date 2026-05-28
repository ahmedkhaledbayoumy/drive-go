import 'package:go_router/go_router.dart';
import '../features/shared/placeholder_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/notifications_screen.dart';
import '../features/history/screens/review_screen.dart';
import 'auth_provider.dart';

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

        // Guests can browse cars but not access these:
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

        // V1 — Authentication
        GoRoute(
            path: '/login',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Login', verticalOwner: 'V1 — Authentication')),
        GoRoute(
            path: '/signup',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Sign Up', verticalOwner: 'V1 — Authentication')),
        GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Forgot Password',
                verticalOwner: 'V1 — Authentication')),
        GoRoute(
            path: '/profile',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Profile', verticalOwner: 'V1 — Authentication')),
        GoRoute(
            path: '/settings',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Settings', verticalOwner: 'V1 — Authentication')),

        // V2 — Marketplace Discovery
        GoRoute(
            path: '/home',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Home',
                verticalOwner: 'V2 — Marketplace Discovery')),
        GoRoute(
            path: '/search',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Search',
                verticalOwner: 'V2 — Marketplace Discovery')),
        GoRoute(
            path: '/favorites',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'Favorites',
                verticalOwner: 'V2 — Marketplace Discovery')),

        // V3 — Car Details, Listings, Owner Profile
        GoRoute(
            path: '/car/:id',
            builder: (_, s) => PlaceholderScreen(
                screenName: 'Car Details (id: ${s.pathParameters['id']})',
                verticalOwner: 'V3 — Listings')),
        GoRoute(
            path: '/list-car',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'List a Car', verticalOwner: 'V3 — Listings')),
        GoRoute(
            path: '/my-listings',
            builder: (_, __) => const PlaceholderScreen(
                screenName: 'My Listings', verticalOwner: 'V3 — Listings')),
        GoRoute(
            path: '/owner/:id',
            builder: (_, s) => PlaceholderScreen(
                screenName: 'Owner Profile (id: ${s.pathParameters['id']})',
                verticalOwner: 'V3 — Listings')),

        // V4 — Booking, Chat, Mock Payment
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

        // V5 — History, Reviews, Notifications
        GoRoute(
            path: '/history',
            builder: (_, __) => const HistoryScreen()),
        GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen()),
        GoRoute(
            path: '/review/:bookingId',
            builder: (_, state) => ReviewScreen(bookingId: state.pathParameters['bookingId']!)),
      ],
    );
  }
}
