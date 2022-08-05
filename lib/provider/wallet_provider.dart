import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
// import 'package:web3dart/src/crypto/formatting.dart';

import '../core/services/contract_service.dart';
import '../core/services/gasprice_service.dart';
import '../core/services/wallet_service.dart';
import '../config/config.dart';
enum WalletState { empty, loading, loaded, success, error, logOut }

class WalletProvider with ChangeNotifier {
  final WalletService _walletService;
  final Web3Client _client;
  final GasPriceService _gasPriceService;
  final ContractService _contractService;
  // final AppProvider _appProvider;

  WalletProvider(
    this._walletService,
    this._client,
    this._gasPriceService,
    this._contractService,
    // this._appProvider,
    // this._userProvider,
  );

  WalletState state = WalletState.empty;
  String errMessage = '';

  late Credentials cred;
  late EthereumAddress address;
  EtherAmount? balance;

  //Transaction Specific
  GasInfo? gasInfo;
  Transaction? transactionInfo;
  double totalAmount = 0;
  String lastTxHash = '';
  double maticPrice = 0;

  //Transaction Async
  Function? onNetworkConfirmationRun;

  getBalance() async {
    balance = await _client.getBalance(address);
    debugPrint('balance: ${balance}');
    _handleLoaded();
    notifyListeners();
  }

  //Get Transaction Cost
  getTransactionFee(Transaction transaction) async {
    try {
      transactionInfo = transaction;
      gasInfo = null;

      _handleLoading();

      gasInfo = null;

      gasInfo = await _gasPriceService.getGasInfo(transaction);
      debugPrint('gasInfo: $gasInfo');

      if (transactionInfo!.value == null) {
        totalAmount = gasInfo!.totalGasRequired;
      } else {
        totalAmount = gasInfo!.totalGasRequired +
            transactionInfo!.value!.getValueInUnit(EtherUnit.ether);
      }

      debugPrint('totalAmount: $totalAmount');

      final contract = _contractService.priceFeed;
      debugPrint('contract: $contract');

      final price = await _client.call(
        contract: contract,
        function: contract.function('latestRoundData'),
        params: [],
      );
      debugPrint('price: $price');

      maticPrice = price[0] / BigInt.from(10).pow(8);
      debugPrint('maticPrice: $maticPrice');

      getBalance();
      debugPrint('getBalance: $getBalance');
    } catch (e) {
      debugPrint('Error at WallerProvider -> GetTransactionFee: $e');
      final err = e.toString();
      final split = err.split('"');
      _handleError(err);
      _handleError(split[1]);
    }
  }

  sendTransaction(Transaction transaction) async {
    debugPrint('Sending transaction');
    try {
      _handleLoading();

      lastTxHash = '';
      lastTxHash = await _client.sendTransaction(
        cred,
        transaction,
        chainId: null,
        fetchChainIdFromNetworkId: true,
      );

      debugPrint('Transaction completed $lastTxHash');

      await getBalance();
      await _walletService.setLastTxHash(lastTxHash.toString());

      await Future.delayed(const Duration(seconds: 18));

      // _userProvider.fetchUserInfo();

      _handleSuccess();

      return;
    } catch (e) {
      debugPrint('Error at WalletProvider -> sendTransaction: $e');
      _handleError(e);
    }
  }

  sendTransactionWithThirdParty(Credentials cred, Transaction transaction) async {
    debugPrint('Sending transaction');
    try {
      _handleLoading();

      lastTxHash = '';
      lastTxHash = await _client.sendTransaction(
        cred,
        transaction,
        chainId: null,
        fetchChainIdFromNetworkId: true,
      );

      debugPrint('Transaction completed $lastTxHash');

      await getBalance();
      await _walletService.setLastTxHash(lastTxHash.toString());

      // await Future.delayed(const Duration(seconds: 10));

      // _userProvider.fetchUserInfo();
      _handleSuccess();
    } catch (e) {
      debugPrint('Error at WalletProvider -> sendTransactionWithThirdParty: $e');
      // if (e.toString().contains('User canceled')) {
      //   lastTxHash = e.toString();
      // }
      lastTxHash = e.toString();
      // _handleError(e);
    }
    return lastTxHash;
  }

  buildTransaction(String contractAddress, String fName, List<dynamic> args,
      [double? value]) async {
    final contract =
        await _contractService.loadCollectionContract(contractAddress);

    final transaction = Transaction.callContract(
      from: address,
      contract: contract,
      value: value == null
          ? null
          : EtherAmount.fromUnitAndValue(
              EtherUnit.gwei,
              BigInt.from(value * pow(10, 9)),
            ),
      function: contract.function(fName),
      parameters: args,
    );

    getTransactionFee(transaction);
  }

  initializeWallet() async {
    cred = _walletService.initalizeWallet();
    // address = EthereumAddress.fromHex(publicKey);
    address = await cred.extractAddress();
    debugPrint('address: ${address}');
    getBalance();

    _handleLoaded();
  }

  initializeWalletWithThirdParty(String publicKey) async {
    // cred = _walletService.initalizeWallet();
    address = EthereumAddress.fromHex(publicKey);
    debugPrint('address: ${address}');
    getBalance();

    _handleLoaded();
  }

  initializeFromKey(String privateKey) async {
    try {
      cred = _walletService.initalizeWallet(privateKey);
      address = await cred.extractAddress();
      await _walletService.setPrivateKey(privateKey);
      await _walletService.setPublicKey(address.toString());
      getBalance();

      _handleSuccess();
    } on FormatException catch (e) {
      debugPrint('Error: ${e.message}');

      _handleError('Invalid private key');
    } catch (e) {
      debugPrint('Error: $e');

      _handleError(e);
    }
  }

  initializeFromMetaMask(provider,publicKey) async {
    try {
      cred = _walletService.initalizeWalletMetaMask(provider);
      address = EthereumAddress.fromHex(publicKey);
      debugPrint('address: ${address}');
      // address = await cred.extractAddress();
      // cred.extractAddress();

      await _walletService.setPublicKey(address.toString());
      getBalance();
      _handleLoaded();
    } on FormatException catch (e) {
      debugPrint('Error: ${e.message}');

      _handleError('Invalid private key');
    } catch (e) {
      debugPrint('Error: $e');

      _handleError(e);
    }
  }

  createWallet() async {
    _handleLoading();
    cred = _walletService.generateRandomAccount();
    address = await cred.extractAddress();
    cred.extractAddress();

    getBalance();

    _handleSuccess();
  }

  void _handleEmpty() {
    state = WalletState.empty;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoading() {
    state = WalletState.loading;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoaded() {
    state = WalletState.loaded;
    errMessage = '';
    notifyListeners();
  }

  void _handleSuccess() {
    state = WalletState.success;
    errMessage = '';
    notifyListeners();
    Timer(const Duration(milliseconds: 450), _handleEmpty);
  }

  void _handleError(e) {
    state = WalletState.error;
    errMessage = e.toString();
    notifyListeners();
  }
}
