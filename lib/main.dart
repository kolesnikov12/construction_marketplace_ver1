import 'package:construction_marketplace/screens/tenders/listing_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/locale_provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/screens/home_screen.dart';
import 'package:construction_marketplace/screens/auth/login_screen.dart';
import 'package:construction_marketplace/screens/auth/register_screen.dart';
import 'package:construction_marketplace/screens/tenders/tender_list_screen.dart';
import 'package:construction_marketplace/screens/tenders/tender_detail_screen.dart';
import 'package:construction_marketplace/screens/tenders/create_tender_screen.dart';
import 'package:construction_marketplace/screens/listings/listing_detail_screen.dart';
import 'package:construction_marketplace/screens/listings/create_listing_screen.dart';
import 'package:construction_marketplace/screens/profile/profile_screen.dart';
import 'package:construction_marketplace/screens/favorites/favorites_screen.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TenderProvider>(
          create: (_) => TenderProvider(),
          update: (_, authProvider, previousTenderProvider) {
            final provider = previousTenderProvider ?? TenderProvider();
            provider.update(authProvider.token, authProvider.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ListingProvider>(
          create: (_) => ListingProvider(),
          update: (_, authProvider, previousListingProvider) {
            final provider = previousListingProvider ?? ListingProvider();
            provider.update(authProvider.token, authProvider.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (ctx, localeProvider, _) => MaterialApp(
          title: 'Construction Marketplace',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('fr', ''), // French
          ],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (ctx) => Consumer<AuthProvider>(
              builder: (ctx, authProvider, _) =>
              authProvider.isAuth ? HomeScreen() : LoginScreen(),
            ),
            HomeScreen.routeName: (ctx) => HomeScreen(),
            LoginScreen.routeName: (ctx) => LoginScreen(),
            RegisterScreen.routeName: (ctx) => RegisterScreen(),
            TenderListScreen.routeName: (ctx) => TenderListScreen(),
            TenderDetailScreen.routeName: (ctx) => TenderDetailScreen(),
            CreateTenderScreen.routeName: (ctx) => CreateTenderScreen(),
            ListingListScreen.routeName: (ctx) => ListingListScreen(),
            ListingDetailScreen.routeName: (ctx) => ListingDetailScreen(),
            CreateListingScreen.routeName: (ctx) => CreateListingScreen(),
            ProfileScreen.routeName: (ctx) => ProfileScreen(),
            FavoritesScreen.routeName: (ctx) => FavoritesScreen(),
          },
        ),
      ),
    );
  }
}