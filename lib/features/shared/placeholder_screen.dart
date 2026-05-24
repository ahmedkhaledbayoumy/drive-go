import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_provider.dart';

class PlaceholderScreen extends StatelessWidget {
  final String screenName;
  final String verticalOwner;

  const PlaceholderScreen({
    super.key,
    required this.screenName,
    required this.verticalOwner,
  });

  String _localizedTitle(AppLocalizations t) {
    switch (screenName.toLowerCase()) {
      case 'home':
        return t.home;
      case 'favorites':
        return t.favorites;
      case 'my listings':
        return t.myListings;
      case 'search':
        return t.search;
      case 'profile':
        return t.profile;
      case 'settings':
        return t.settings;
      default:
        return screenName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_localizedTitle(t)),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: t.profile,
              onPressed: () => context.push('/profile'),
            ),
          if (auth.isAuthenticated || auth.isGuest)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: t.settings,
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(_localizedTitle(t),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(verticalOwner,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        )),
              ),
              const SizedBox(height: 24),
              Text('To be built by the assigned team member.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
