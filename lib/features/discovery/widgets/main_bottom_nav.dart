import 'package:drive_go/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared bottom navigation for discovery screens.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key});

  static int indexForLocation(String location) {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/favorites')) return 2;
    if (location.startsWith('/list-car')) return 3;
    if (location.startsWith('/history')) return 4;
    return 0;
  }

  static void onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/search');
      case 2:
        context.go('/favorites');
      case 3:
        context.push('/list-car');
      case 4:
        context.go('/history');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = indexForLocation(location);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
      onTap: (index) => onTap(context, index),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          label: t.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          label: t.search,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite_border),
          label: t.favorites,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, color: colorScheme.secondary),
          label: t.addListing,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: t.history,
        ),
      ],
    );
  }
}
