import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WalletService {
  final SharedPreferences _prefs;

  WalletService(this._prefs);

  //GENERATE RANDOM WALLET
  Credentials generateRandomAccount() {
    // print(Random.secure());
    final cred = EthPrivateKey.createRandom(Random.secure());

    final key = bytesToHex(
      cred.privateKey,
      padToEvenLength: true,
    );

    setPrivateKey(key);

    setPublicKey(cred.address.toString());

    return cred;
  }

  ///Retrieve cred from private key
  Credentials initalizeWallet([String? key]) =>
      EthPrivateKey.fromHex(key ?? getPrivateKey());

  Credentials initalizeWalletMetaMask(provider) {
    final cred = WalletConnectEthereumCredentials(provider: provider);
    return cred;
  }


  ///Retrieve Private key from prefs
  ///If not present send empty
  String getPrivateKey() => _prefs.getString('user_private_key') ?? '';

  ///Retrieve Public key from prefs
  ///If not present send empty
  String getPublicKey() => _prefs.getString('user_public_key') ?? '';

  ///Retrieve LastTxHash from prefs
  ///If not present send empty
  String getLastTxHash() => _prefs.getString('user_last_txn_hash') ?? '';

  ///set private key
  Future<void> setPrivateKey(String value) async =>
      await _prefs.setString('user_private_key', value);

  ///set public key
  Future<void> setPublicKey(String value) async =>
      await _prefs.setString('user_public_key', value);

  ///set lastTxHash
  Future<void> setLastTxHash(String value) async =>
      await _prefs.setString('user_last_txn_hash', value);

}

class WalletConnectEthereumCredentials extends Credentials {
  WalletConnectEthereumCredentials({required this.provider});
  // The ethereum address belonging to this credential.


  final EthereumWalletConnectProvider provider;
  // final List<int> codeUnits = '0xD7d35eF34b41E405A9218DFF152F4d0FD9B153f0';
  // final Uint8List unit8List = Uint8List.fromList(codeUnits);


  @override
  Future<EthereumAddress> extractAddress() {
    // TODO: implement extractAddress
    throw UnimplementedError();
  }

  Future<String> sendTransaction(Transaction transaction) async {
    final hash = await provider.sendTransaction(
      from: transaction.from!.hex,
      to: transaction.to?.hex,
      data: transaction.data,
      gas: transaction.maxGas,
      gasPrice: transaction.gasPrice?.getInWei,
      value: transaction.value?.getInWei,
      nonce: transaction.nonce,
    );

    return hash;
  }

  // @override
  // EthereumAddress get address {
  //   return EthereumAddress(publicKeyToAddress(unit8List));
  // }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    // TODO: implement signToSignature
    throw UnimplementedError();
  }
}
