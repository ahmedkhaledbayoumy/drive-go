import 'package:drive_go/features/discovery/providers/discovery_provider.dart';
import 'package:drive_go/features/discovery/widgets/main_bottom_nav.dart';
import 'package:drive_go/l10n/app_localizations.dart';
import 'package:drive_go/services/auth_provider.dart';
import 'package:drive_go/widgets/car_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.savedCollection),
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.appBarTheme.backgroundColor
            : colorScheme.primary,
        foregroundColor: theme.brightness == Brightness.dark
            ? theme.appBarTheme.foregroundColor
            : colorScheme.onPrimary,
      ),
      body: !auth.isAuthenticated
          ? _SignInPrompt(t: t)
          : Consumer<DiscoveryProvider>(
              builder: (context, discovery, _) {
                final favoriteCars = discovery.favoriteCars;

                if (favoriteCars.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.noSavedCars,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () => context.go('/home'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.primary),
                              minimumSize: const Size(200, 48),
                            ),
                            child: Text(t.browseCars),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: favoriteCars.length,
                  itemBuilder: (context, index) {
                    final car = favoriteCars[index];
                    return CarCard(
                      car: car,
                      onBookNow: () => context.push('/car/${car.id}'),
                      onTap: () => context.push('/car/${car.id}'),
                      isFavorite: discovery.isFavorite(car.id),
                      onFavoriteToggle: () =>
                          discovery.toggleFavorite(car.id),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  final AppLocalizations t;

  const _SignInPrompt({required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              t.signInToSave,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                child: Text(t.signIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
