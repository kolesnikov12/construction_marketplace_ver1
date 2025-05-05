import 'package:construction_marketplace/widgets/auth_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'bloc/auth_bloc.dart';
import 'bloc/tender_bloc.dart';
import 'bloc/listing_bloc.dart';
import 'bloc/bloc_provider.dart';
import 'utils/l10n/app_localizations.dart';
import 'utils/app_theme.dart';
import 'providers/locale_provider.dart';
import 'providers/category_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/tenders/tender_list_screen.dart';
import 'screens/tenders/tender_detail_screen.dart';
import 'screens/tenders/create_tender_screen.dart';
import 'screens/listings/listing_detail_screen.dart';
import 'screens/listings/create_listing_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/tenders/listing_list_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: BlocProvider<AuthBloc>(
        create: () => AuthBloc(),
        child: BlocProvider<TenderBloc>(
          create: () => TenderBloc(),
          child: BlocProvider<ListingBloc>(
            create: () => ListingBloc(),
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
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                initialRoute: '/',
                routes: {
                  '/': (ctx) => AuthStateWidget(),
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
          ),
        ),
      ),
    );
  }
}