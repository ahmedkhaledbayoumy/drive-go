import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/discovery/providers/discovery_provider.dart';
import 'services/app_router.dart';
import 'services/auth_provider.dart';
import 'services/language_provider.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleFonts.pendingFonts([
    GoogleFonts.cairo(),
    GoogleFonts.cairo(fontWeight: FontWeight.w600),
    GoogleFonts.cairo(fontWeight: FontWeight.w700),
    GoogleFonts.cairo(fontWeight: FontWeight.w800),
  ]);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final themeProvider = ThemeProvider();
  await themeProvider.loadFromPrefs();

  final languageProvider = LanguageProvider();
  await languageProvider.loadFromPrefs();

  final authProvider = AuthProvider();
  final router = AppRouter.create(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, DiscoveryProvider>(
          create: (_) => DiscoveryProvider(userId: null),
          update: (_, auth, __) =>
              DiscoveryProvider(userId: auth.currentProfile?.id),
        ),
      ],
      child: DriveGoApp(router: router),
    ),
  );
}

class DriveGoApp extends StatelessWidget {
  final GoRouter router;
  const DriveGoApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp.router(
      title: 'Drive Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      locale: languageProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
