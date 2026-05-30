
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import '../features/discovery/models/filter_state.dart';

// V3 — Listings
import '../features/listings/car_details_screen.dart';
import '../features/listings/edit_listing_screen.dart';
import '../features/listings/my_listings_screen.dart';
import '../features/listings/owner_profile_screen.dart';
import '../features/listings/rent_my_car_screen.dart';

// V4 — Booking, Chat, Mock Payment
import '../features/booking/providers/booking_provider.dart';
import '../features/booking/screens/booking_details_screen.dart';
import '../features/booking/screens/chat_screen.dart';
import '../features/booking/screens/payment_screen.dart';
import '../features/booking/screens/booking_confirmation_screen.dart';

// V5 — History, Notifications, Reviews
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/notifications_screen.dart';
import '../features/history/screens/review_screen.dart';

// Admin
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_cars_screen.dart';
import '../features/admin/screens/admin_bookings_screen.dart';
import '../features/admin/providers/admin_provider.dart';

// Shared
import '../features/welcome/welcome_screen.dart';

import '../models/models.dart';
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
        final isAdminRoute = path.startsWith('/admin');

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
        final isBlockedForGuest =
            guestBlocked.any((r) => path.startsWith(r));

        if (auth.isUnauthenticated && !isWelcome && !isAuthRoute) {
          return '/welcome';
        }
        if (auth.isGuest && isBlockedForGuest) {
          return '/login';
        }

        // If authenticated but profile hasn't loaded yet, stay put and wait.
        // The router will re-run once _loadProfile() calls notifyListeners().
        if (auth.isAuthenticated && !auth.profileLoaded) {
          return null;
        }

        // Admin-only route guard — non-admin trying to reach /admin
        if (isAdminRoute && auth.isAuthenticated && !auth.isAdmin) {
          return '/home';
        }

        // Redirect admin users away from welcome/auth screens to admin dashboard
        if (auth.isAuthenticated &&
            (isWelcome || isAuthRoute) &&
            auth.isAdmin) {
          return '/admin';
        }

        // Redirect regular authenticated users away from welcome/auth screens
        if (auth.isAuthenticated && (isWelcome || isAuthRoute)) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, __) => '/welcome'),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),

        // V1 — Authentication
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
        GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

        // V2 — Marketplace Discovery
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

        // V3 — Listings
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

        // V4 — Booking, Chat, Mock Payment
        GoRoute(
          path: '/booking/new',
          builder: (context, state) {
            final car = state.extra as Car?;
            return ChangeNotifierProvider(
              create: (_) => BookingProvider(),
              child: BookingDetailsScreen(car: car),
            );
          },
        ),
        GoRoute(
          path: '/booking/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final car = state.extra as Car?;
            return ChangeNotifierProvider(
              create: (_) => BookingProvider(),
              child: BookingDetailsScreen(bookingId: id, car: car),
            );
          },
        ),
        GoRoute(
          path: '/booking-confirmation/:bookingId',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return ChangeNotifierProvider(
              create: (_) => BookingProvider(),
              child: BookingConfirmationScreen(bookingId: bookingId),
            );
          },
        ),
        GoRoute(
          path: '/chat/:bookingId',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return ChangeNotifierProvider(
              create: (_) => BookingProvider(),
              child: ChatScreen(bookingId: bookingId),
            );
          },
        ),
        GoRoute(
          path: '/payment/:bookingId',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return ChangeNotifierProvider(
              create: (_) => BookingProvider(),
              child: PaymentScreen(bookingId: bookingId),
            );
          },
        ),

        // V5 — History, Notifications, Reviews
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen()),
        GoRoute(
            path: '/review/:bookingId',
            builder: (_, s) =>
                ReviewScreen(bookingId: s.pathParameters['bookingId']!)),

        // Admin — protected, admin account type only.
        // ShellRoute keeps a single AdminProvider instance alive across all
        // admin sub-screens so context.watch<AdminProvider>() always resolves.
        ShellRoute(
          builder: (context, state, child) => ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, _) => const AdminDashboardScreen(),
              routes: [
                GoRoute(
                  path: 'users',
                  builder: (context, _) => const AdminUsersScreen(),
                ),
                GoRoute(
                  path: 'cars',
                  builder: (context, _) => const AdminCarsScreen(),
                ),
                GoRoute(
                  path: 'bookings',
                  builder: (context, _) => const AdminBookingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
