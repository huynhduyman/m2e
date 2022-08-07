import 'package:get_it/get_it.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:nfts/provider/health_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import 'config/config.dart';
import 'core/services/contract_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/gasprice_service.dart';
import 'core/services/graphql_service.dart';
import 'core/services/health_service.dart';
import 'core/services/image_picker_service.dart';
import 'core/services/ipfs_service.dart';
import 'core/services/nft_repo.dart';
import 'core/services/wallet_service.dart';
import 'core/services/notification_service.dart';
import 'provider/app_provider.dart';
import 'provider/collection_provider.dart';
import 'provider/creator_provider.dart';
import 'provider/fav_provider.dart';
import 'provider/nft_provider.dart';
import 'provider/search_provider.dart';
import 'provider/user_provider.dart';
import 'provider/wallet_provider.dart';
import 'provider/auth_provider.dart';

final locator = GetIt.instance;

Future<void> init() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // FirebaseAuth _firebaseAuth = await FirebaseAuth.instance;
  //PROVIDER
  locator.registerLazySingleton<AppProvider>(() => AppProvider(
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
      ));

  locator.registerLazySingleton<FavProvider>(() => FavProvider(locator()));
  locator.registerLazySingleton<HealthProvider>(() => HealthProvider(HealthService()));
  locator
      .registerLazySingleton<SearchProvider>(() => SearchProvider(locator()));
  locator.registerLazySingleton<UserProvider>(
      () => UserProvider(locator(), locator()));

  locator.registerLazySingleton<WalletProvider>(() => WalletProvider(
        locator(),
        locator(),
        locator(),
        locator(),
      ));
  locator.registerLazySingleton<AuthProvider>(() => AuthProvider(FirebaseService()));
  locator.registerLazySingleton<CreatorProvider>(
      () => CreatorProvider(locator(), locator()));
  locator.registerLazySingleton<NFTProvider>(() => NFTProvider(
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
      ));
  locator.registerLazySingleton<CollectionProvider>(() => CollectionProvider(
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
        locator(),
      ));

  //SERVICES
  locator.registerSingleton<NotificationService>(NotificationService());
  locator.registerSingleton<HealthService>(HealthService());
  // locator.registerSingleton<HealthService>(HealthService(locator()));
  // locator.registerSingleton<FirebaseService>(FirebaseService());
  locator.registerSingleton<ContractService>(ContractService());
  locator.registerLazySingleton<WalletService>(() => WalletService(locator()));
  locator.registerLazySingleton<NFTRepo>(() => NFTRepo(locator(), locator()));
  locator
      .registerLazySingleton<GraphqlService>(() => GraphqlService(GraphQLClient(
            link: HttpLink(graphqlURL),
            cache: GraphQLCache(),
          )));
  locator.registerLazySingleton<IPFSService>(() => IPFSService(locator()));
  locator.registerLazySingleton<GasPriceService>(
      () => GasPriceService(locator(), locator()));
  locator.registerLazySingleton<ImagePickerService>(() => ImagePickerService());

  //CONFIG
  locator.registerLazySingleton<http.Client>(() => http.Client());

  locator
      .registerLazySingleton<Web3Client>(() => Web3Client(rpcURL, locator()));

  //PLUGINS

  locator.registerLazySingleton<SharedPreferences>(() => prefs);
  // locator.registerLazySingleton<FirebaseAuth>(() => _firebaseAuth);
}
