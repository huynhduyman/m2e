import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nfts/provider/auth_provider.dart';
import 'package:nfts/provider/health_provider.dart';
import 'package:nfts/screens/create_wallet_screen/create_wallet_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/firebase_service.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/size_config.dart';
import 'locator.dart';
import 'locator.dart' as di;
import 'provider/app_provider.dart';
import 'provider/collection_provider.dart';
import 'provider/creator_provider.dart';
import 'provider/fav_provider.dart';
import 'provider/nft_provider.dart';
import 'provider/search_provider.dart';
import 'provider/user_provider.dart';
import 'provider/wallet_provider.dart';
import 'screens/create_collection_screen/create_collection_screen.dart';
import 'screens/create_nft_screen/create_nft_screen.dart';
import 'screens/splash_screen/splash_screen.dart';
import 'screens/tabs_screen/tabs_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locator<AppProvider>()..initialize(),),
        ChangeNotifierProvider(create: (_) => locator<AuthProvider>(),),
        ChangeNotifierProvider(create: (_) => locator<WalletProvider>()),
        ChangeNotifierProvider(create: (_) => locator<CreatorProvider>()),
        ChangeNotifierProvider(create: (_) => locator<CollectionProvider>()),
        ChangeNotifierProvider(create: (_) => locator<NFTProvider>()),
        ChangeNotifierProvider(create: (_) => locator<FavProvider>()),
        ChangeNotifierProvider(create: (_) => locator<SearchProvider>()),
        ChangeNotifierProvider(create: (_) => locator<UserProvider>()),
        ChangeNotifierProvider(create: (_) => locator<HealthProvider>(),),

        // Provider<FirebaseService>(create: (_) => FirebaseService(),
        // ),

        // StreamProvider(
        //   create: (context) => context.read<FirebaseService>().onAuthStateChanged, initialData: null,
        // ),

        // StreamProvider(
        //     create: (_) => FirebaseService().user
        // ),
      ],
      child: SizeConfiguration(
        designSize: const Size(375, 812),
        builder: (_) {
          return MaterialApp(
            title: 'nfts',
            theme: AppTheme.light(),
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            home: const SplashScreen(),
            // home: TestMaticScreen(),
            routes: {
              'create_collection': (_) => const CreateCollectionScreen(),
              'create_nft': (_) => const CreateNFTScreen(),
              'tabs_screen': (_) => const TabsScreen(),
              'create_wallet_screen': (_) => const CreateWalletScreen(),
            },
            // home: const CreateCollectionScreen(),
            // home: const NetworkConfirmationScreen(),
          );
        },
      ),
    );
  }
}