import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/gql_query.dart';
import '../core/services/graphql_service.dart';
import '../core/services/wallet_service.dart';
import '../core/services/firebase_service.dart';
import '../core/utils/utils.dart';
import '../models/collection.dart';
import '../models/nft.dart';
import '../screens/create_wallet_screen/create_wallet_screen.dart';
import '../screens/wallet_connect_thirdparty/wallet_connect_thirdparty.dart';
import 'fav_provider.dart';
import 'user_provider.dart';
import 'wallet_provider.dart';
import 'auth_provider.dart';

enum AppState { empty, loading, loaded, success, error, unauthenticated, notwalletconnected }

class AppProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  final WalletService _walletService;
  final WalletProvider _walletProvider;
  final FavProvider _favProvider;
  final UserProvider _userProvider;
  final GraphqlService _graphql;

  AppProvider(
    this._authProvider,
    this._walletService,
    this._walletProvider,
    this._graphql,
    this._userProvider,
    this._favProvider,
  );

  //APP PROVIDER VAR
  AppState state = AppState.empty;
  String errMessage = '';

  //HOME PAGE
  List<Collection> topCollections = [];
  List<NFT> featuredNFTs = [];

  //CREATOR PAGE
  List<Collection> userCreatedCollections = [];
  List<NFT> userCollected = [];

  // List<

  //METHODS

  bool _isAuthenticated = false;

  bool get isAuthenticated {
    return _isAuthenticated;
  }

  set isAuthenticated(bool newVal) {
    _isAuthenticated = newVal;
    notifyListeners();
  }

  initialize() async {

    // final stateAuthProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint(_authProvider.isSignedIn!.toString());
    debugPrint(_authProvider.getUser.toString());
    if (_authProvider.isSignedIn == false) {
      _handleUnauthenticated();
    }
    // debugPrint(' Firebase auth:${stateAuthProvider.state}');

    final privateKey = _walletService.getPrivateKey();
    final publicKey = _walletService.getPublicKey();
    final lastTxHash = _walletService.getLastTxHash();
    debugPrint('AppProvider initialize publicKey: ${publicKey}');
    debugPrint('AppProvider initialize lastTxHash: ${lastTxHash}');

    if (publicKey.isEmpty) {
      _handleNotWalletConnected();
    }
    // is connected use WalletConnect
    else if (privateKey.isEmpty && publicKey.isNotEmpty) {
      //FIRST - INITIALIZE WALLET
      await _walletProvider.initializeWalletWithThirdParty(publicKey);
      await WalletConnectThirdparty();
      //HOME SCREEN DATA
      await fetchInitialData();

      //FETCH USER PAGES DATA
      _userProvider.fetchUserInfo();

      //Fav Provider
      _favProvider.fetchFav();

      _handleLoaded();
    }
    // is connected use create wallet
    else if (privateKey.isNotEmpty && publicKey.isNotEmpty) {
      //FIRST - INITIALIZE WALLET
      await _walletProvider.initializeWallet();
      //HOME SCREEN DATA
      await fetchInitialData();

      //FETCH USER PAGES DATA
      _userProvider.fetchUserInfo();

      //Fav Provider
      _favProvider.fetchFav();

      _handleLoaded();
    }
    else {
      //FIRST - INITIALIZE WALLET
      await _walletProvider.initializeWallet();
      //HOME SCREEN DATA
      await fetchInitialData();

      //FETCH USER PAGES DATA
      _userProvider.fetchUserInfo();

      //Fav Provider
      _favProvider.fetchFav();

      _handleLoaded();
    }
  }

  fetchInitialData() async {
    // _handleLoading();

    //FETCHING HOME SCREEN DATA
    final data = await _graphql.get(qHome, {'first': 15});

    //Model Collections
    topCollections = data['collections']
        .map<Collection>((collection) => Collection.fromMap(collection))
        .toList();

    //Model NFTS
    featuredNFTs =
        data['nfts'].map<NFT>((collection) => NFT.fromMap(collection)).toList();

    _handleLoaded();
  }

  logOut(BuildContext context) async {
    await _authProvider.signOut();
    _handleUnauthenticated();
    notifyListeners();
    debugPrint('AppProvider logOut ');
  }

  logOutWallet(BuildContext context) async {
    await _walletService.setPrivateKey('');
    await _walletService.setPublicKey('');
    // await _authProvider.signOut();
    // await WalletConnectThirdparty().walletConnect.killSession();

    _handleNotWalletConnected();
    notifyListeners();

    // scheduleMicrotask(() {
    //   Navigation.popAllAndPush(
    //     context,
    //     screen: const CreateWalletScreen(),
    //   );
    // });
  }

  void _handleEmpty() {
    state = AppState.empty;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoading() {
    state = AppState.loading;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoaded() {
    state = AppState.loaded;
    errMessage = '';
    notifyListeners();
  }

  void _handleUnauthenticated() {
    state = AppState.unauthenticated;
    errMessage = '';
    notifyListeners();
  }

  void _handleNotWalletConnected() {
    state = AppState.notwalletconnected;
    errMessage = '';
    notifyListeners();
  }

  void _handleSuccess() {
    state = AppState.success;
    errMessage = '';
    notifyListeners();
  }

  void _handleError(e) {
    state = AppState.error;
    errMessage = e.toString();
    notifyListeners();
  }
}
