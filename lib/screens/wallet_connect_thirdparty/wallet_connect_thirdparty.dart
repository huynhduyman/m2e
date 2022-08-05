import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';

import 'package:http/http.dart'; //You can also import the browser version
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/model/typed_data.dart';

import '../../core/services/firebase_service.dart';
import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../provider/app_provider.dart';
import '../../provider/auth_provider.dart';
import '../../provider/wallet_provider.dart';
import '../user_screen/edit_user_info_screen.dart';
import '../splash_screen/splash_screen.dart';
import '../../constants.dart';
import '../../models/wallet_connect_registry.dart';
import '../../core/widgets/wallet_connect_dialog/wallet_connect_dialog.dart';
import '../../core/services/wallet_service.dart';
import '../../screens/create_wallet_screen/create_wallet_screen.dart';

class EnvironmentConfig {
  static const kExampleMinterAddress = String.fromEnvironment('MINTER_ADDRESS');
  static const kExampleMinterPrivateKey = String.fromEnvironment('MINTER_PRIVATE_KEY');
}

class WalletConnectThirdparty extends StatefulWidget with WidgetsBindingObserver {
  const WalletConnectThirdparty({Key? key}) : super(key: key);
  @override
  _WalletConnectThirdpartyState createState() => _WalletConnectThirdpartyState();
}

// Global Settings
var logger = Logger(printer: SimpleLogPrinter(''));
late String basePath;
late int chainId;
late String collection;
late String minter;
late String tokenId;
late String mediaIpfsCID; // Primary NFT Image
late String nftMetadataIpfsCID; // NFT JSON Metadata with attributes in IPFS
late String raribleDotCom;
late String multichainBaseUrl;
late String multichainBlockchain;
late String blockExplorer;
late WalletConnect walletConnect;
late BlockchainFlavor blockchainFlavor;
late WalletConnectRegistryListing walletListing;
late Credentials _credentials;
late Web3Client _client;
bool visible = false;
String? stringTxnHash;
String? nftStoreUri;
String textWalletConnect = 'WalletConnect';

/// Logging Formatter
/// Leveraged from:https://medium.com/flutter-community/a-guide-to-setting-up-better-logging-in-flutter-3db8bab2000e
class SimpleLogPrinter extends LogPrinter {
  final String className;
  SimpleLogPrinter(this.className);
  @override
  List<String> log(LogEvent event) {
    DateTime dateTime = DateTime.now();
    //var color = PrettyPrinter.levelColors[event.level];
    var emoji = PrettyPrinter.levelEmojis[event.level];
    return ['${dateTime.toUtc()} $emoji $className - ${event.message}'];
    //println(color('$emoji $className - ${event.message}'));
  }
}

class WalletConnectEthereumCredentials extends CustomTransactionSender {
  WalletConnectEthereumCredentials({required this.provider});

  final EthereumWalletConnectProvider provider;

  @override
  Future<EthereumAddress> extractAddress() {
    // TODO: implement extractAddress
    throw UnimplementedError();
  }

  @override
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

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    // TODO: implement signToSignature
    throw UnimplementedError();
  }
}


///  Query the WalletConnect Registry for compatibleWallets
///  [limit] specifies the total number of wallets to return
///
/// Example code does not support multiple requests across pages.
/// Registry API Documentation available here: https://docs.walletconnect.com/2.0/api/registry-api
Future<List<WalletConnectRegistryListing>> readWalletRegistry({int limit = 4}) async {
  List<WalletConnectRegistryListing> listings = [];

  var client = http.Client();
  try {
    http.Response response;

    final queryParameters = {
      'entries': '$limit',
      'page': '1',
    };

    logger.d('Requesting WalletConnect Registry for first $limit wallets.');
    response = await client.get(
      Uri.https(
        'registry.walletconnect.com',
        'api/v1/wallets',
        queryParameters,
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      //log(response.body);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;

      if (decodedResponse != null && decodedResponse['listings'] != null) {
        // Present user with list of supported wallets (IOS)

        for (Map<String, dynamic> entry in decodedResponse['listings'].values) {
          listings.add(WalletConnectRegistryListing.fromMap(entry));
          //logger.d('Processing ${listings.last.name}');
        }
      }
      return listings;
    } else {
      logger.e('Unexpected server error: ${response.statusCode}: ${response.reasonPhrase}.');
    }
  } catch (e) {
    logger.e('Unexpected protocol error: $e');
  } finally {
    client.close();
  }
  return listings;
}

/// Updates global walletListing so subsequent requests can be directed to the wallet
void setWalletListing(WalletConnectRegistryListing listing) {
  walletListing = listing;
}

/// Calls the Rarible API to get the next tokenId for the given collection
///  [collection] the address of the Lazy Mint compatible ERC-721 contract
///  [minter] the address of the primary creator who will sign the later
///           Lazy Mint request
///
///  Ethereum API nft-collection-controller:generateNftTokenId
///  https://ethereum-api.rarible.org/v0.1/doc#operation/generateNftTokenId
Future<String> getNextTokenId({required String minter}) async {
  Stopwatch stopwatch = Stopwatch();
  String apiUrl = '${basePath}v0.1/nft/collections/$collection/generate_token_id';
  logger.d('Requesting next token if from $apiUrl.');

  var client = http.Client();
  final apiUri = Uri.parse(apiUrl);
  final hostname = apiUri.host;

  stopwatch.start();
  final ipAddress = await InternetAddress.lookup(hostname);
  stopwatch.stop();
  logger.i('${stopwatch.elapsedMilliseconds}ms for DNS lookup of hostname $hostname ($ipAddress)');

  stopwatch.reset();
  stopwatch.start();
  try {
    var response = await client.get(
      Uri.https(apiUri.host.toString(), apiUri.path.toString(), {'minter': minter}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    stopwatch.stop();
    logger.i('${stopwatch.elapsedMilliseconds}ms for API $apiUri');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      // logger.d('200 ok: $decodedResponse');
      tokenId = decodedResponse['tokenId'];
    } else {
      var decodedResponse = jsonDecode(response.body);
      logger.e('response: ${response.statusCode}: ${response.reasonPhrase} / ${response.body.toString()}.');
      return 'Error: ${response.statusCode}:${response.reasonPhrase} - ${decodedResponse['message']}.';
    }
  } on SocketException {
    logger.e('SocketException');
    return 'Error: We are unable to initiate communicate with our backend. (SocketException).';
  } on TimeoutException {
    logger.e('TimeoutException');
    return 'Error: Our rarible servers are taking too long to respond. (TimeoutException).';
  } catch (e) {
    logger.e('Error: Ok, we were not expecting this error: $e');
  } finally {
    client.close();
  }
  return tokenId;
}

/// Build Lazy Mint SignTypedData Form
TypedMessage createMint721TypedMessage({
  required int collectionChainId,
  required String collectionAddress,
  required Map<String, dynamic> lazyMintFormJson,
}) {
  // We need to present the user with a signing request that can be
  // rendered/presented properly by the signing wallets.  The TypedDataMessage
  // provides the structure definition followed by the message to be signed.
  final TypedMessage mint721TypedMessage = TypedMessage(
    // Define the types used below.  These should not change
    types: {
      // The HOW to understand and parse the data to sign.
      // node_modules/@rarible/protocol-ethereum-sdk/build/nft/eip712.d.ts
      "EIP712Domain": [
        TypedDataField(name: "name", type: "string"),
        TypedDataField(name: "version", type: "string"),
        TypedDataField(name: "chainId", type: "uint256"),
        TypedDataField(name: "verifyingContract", type: "address")
      ],
      // Part definition - not an array of Part[] like below
      "Part": [
        TypedDataField(name: "account", type: "address"),
        TypedDataField(name: "value", type: "uint96"),
      ],
      "Mint721": [
        TypedDataField(name: "tokenId", type: "uint256"),
        TypedDataField(name: "tokenURI", type: "string"),
        TypedDataField(name: "creators", type: "Part[]"), // This is an array[] of Part
        TypedDataField(name: "royalties", type: "Part[]"), // This is an array[] of Part
      ],
    },
    // This is the data that we will present to sign, a good UI will only show this
    // half in the signing request verification
    primaryType: "Mint721",
    domain: EIP712Domain(
      // Details of the form and where to find the contract to verify it
      name: "Mint721",
      version: "1",
      chainId: collectionChainId, //  must match the collection's chainId or the signature will not verify
      verifyingContract: collectionAddress, // the lazy mint enabled ERC-721 contract address
      salt: "0", // do better than this
    ),
    // The "WHAT" data we are asking to sign. This will later get the signature(s) appended to it.
    message: lazyMintFormJson,
  );

  //String jsonData = jsonEncode(rawTypedData);
  //prettyPrint = encoder.convert(rawTypedData);
  //log('SignTypedData---\n$prettyprint\n---');
  return mint721TypedMessage;
}

/// Rarible API call to perform the Lazy mint requested
/// [message] JSON lazy mint form with the creators' signature(s) appended
///           (from the SignedTypedData requests)
///
/// Ethereum API nft-lazy-mint-controller:mintNftAsset
/// https://ethereum-api.rarible.org/v0.1/doc#operation/mintNftAsset
Future<String?> requestLazyMint(Map<String, dynamic> message) async {
  Stopwatch stopwatch = Stopwatch();
  String apiUrl = '${basePath}v0.1/nft/mints';
  logger.d('Requesting NFT mint from $apiUrl.');

  String hostname = Uri.parse(apiUrl).host;
  stopwatch.start();
  final ipAddress = await InternetAddress.lookup(hostname);
  stopwatch.stop();
  logger.i('${stopwatch.elapsedMilliseconds}ms for DNS lookup of hostname $hostname ($ipAddress)');
  final statDnsLookup = stopwatch.elapsedMilliseconds;

  var client = http.Client();
  stopwatch.start();
  try {
    var response = await client.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(message),
    );
    stopwatch.stop();
    logger.i('${stopwatch.elapsedMilliseconds - statDnsLookup}ms for API: $apiUrl ($ipAddress)');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      logger.d('200 ok: $decodedResponse');
    } else {
      var decodedResponse = jsonDecode(response.body);
      logger.e('response: ${response.statusCode}: ${response.reasonPhrase} / ${response.body.toString()}.');
      return 'Error: ${response.statusCode}:${response.reasonPhrase} - ${decodedResponse['message']}.';
    }
  } on SocketException {
    logger.e('SocketException');
    return 'Error: We are unable to initiate communicate with our backend. (SocketException).';
  } on TimeoutException {
    logger.e('TimeoutException');
    return 'Error: Our backend servers are taking too long to respond. (TimeoutException).';
  } catch (e) {
    logger.e('Error: Ok, we were not expecting this error: $e');
  } finally {
    client.close();
  }
  logger.i('getNftLazyItemById -> ${basePath}v0.1/nft/items/$collection:$tokenId/lazy');
  return 'OK!';
}

Future<String> signTransaction({required BuildContext context, required WalletConnect walletConnector}) async {

  // For signing requests for a connected wallet, only provide the existing session id and version number.
  String walletConnectTopicVersion = 'wc:${walletConnect.session.handshakeTopic}@${walletConnect.session.version}';
  String walletConnectUri = '';
  String walletConnectSignature = '';

  if (Theme.of(context).platform == TargetPlatform.android) {
    // Android OS helps the user choose their wallet
    walletConnectUri = walletConnectTopicVersion;
  } else {
    // IOS has selected a wallet listing from the WalletConnect Registry to use
    logger
        .d('Launching configured wallet ${walletListing.name} using universal link ${walletListing.mobile.universal}');
    walletConnectUri = walletListing.mobile.universal + '/wc?uri=${Uri.encodeComponent(walletConnectTopicVersion)}';
  }
  bool result = await launchUrl(Uri.parse(walletConnectUri), mode: LaunchMode.externalApplication);
  if (result == false) {
    // Application specific link didn't work, so we may redirect to the app store to get a wallet
    result = await launchUrl(Uri.parse(walletConnectUri));
    if (result == false) {
      logger.e('Could not launch $walletConnectUri');
    }
  }

  // If the wallet isn't already opened, give it a change to startup
  sleep(const Duration(milliseconds: 1000));

  logger.e('walletConnector sendCustomRequest.');

  final sender = EthereumAddress.fromHex(walletConnector.session.accounts[0]);
  final transaction = Transaction(
    to: EthereumAddress.fromHex('0x0d9945b9445a14a40459656C0202A10071fdfDa8'),
    from: sender,
    gasPrice: EtherAmount.inWei(BigInt.one),
    maxGas: 100000,
    value: EtherAmount.fromUnitAndValue(EtherUnit.finney, 1),
  );

  // final fee = await _client.estimateGas(
  //   sender: sender,
  //   to: transaction.to,
  //   value: transaction.value,
  //   data: transaction.data,
  // );
  //
  // logger.d('estimateGas fee = $fee');



  // Ask WalletConnect wallet to sign the request
  try {
    // Sign the transaction
    final requestResult = await _client.sendTransaction(_credentials, transaction);
    logger.d('WalletConnect signature = $requestResult');
    if (requestResult is String) {
      walletConnectSignature = requestResult; // as String;
    }
  } on Exception catch (e) {
    logger.e('walletConnector sendCustomRequest Exception .');
    logger.e(e);
    if (e.toString().contains('User canceled')) {
      logger.e('User Cancelled Connection Request.');
    }
  }
  return walletConnectSignature;
}

Future<String> signTypedDataWithWalletConnect(
    {required BuildContext context, required WalletConnect walletConnector, required TypedMessage typedMessage}) async {
  // For signing requests for a connected wallet, only provide the existing session id and version number.
  String walletConnectTopicVersion = 'wc:${walletConnect.session.handshakeTopic}@${walletConnect.session.version}';
  String walletConnectUri = '';
  String walletConnectSignature = '';

  if (Theme.of(context).platform == TargetPlatform.android) {
    // Android OS helps the user choose their wallet
    walletConnectUri = walletConnectTopicVersion;
  } else {
    // IOS has selected a wallet listing from the WalletConnect Registry to use
    logger
        .d('Launching configured wallet ${walletListing.name} using universal link ${walletListing.mobile.universal}');
    walletConnectUri = walletListing.mobile.universal + '/wc?uri=${Uri.encodeComponent(walletConnectTopicVersion)}';
  }
  bool result = await launchUrl(Uri.parse(walletConnectUri), mode: LaunchMode.externalApplication);
  if (result == false) {
    // Application specific link didn't work, so we may redirect to the app store to get a wallet
    result = await launchUrl(Uri.parse(walletConnectUri));
    if (result == false) {
      logger.e('Could not launch $walletConnectUri');
    }
  }

  // If the wallet isn't already opened, give it a change to startup
  sleep(const Duration(milliseconds: 1000));

  logger.e('walletConnector sendCustomRequest.');
  logger.d(jsonEncode(typedMessage));

  // Ask WalletConnect wallet to sign the request
  try {
    final requestResult = await walletConnector.sendCustomRequest(
      method: "eth_signTypedData",
      params: [
        minter,
        jsonEncode(typedMessage),
      ],
    );
    logger.d('WalletConnect signature = $requestResult');
    if (requestResult is String) {
      walletConnectSignature = requestResult; // as String;
      logger.e('walletConnector sendCustomRequest requestResult: $walletConnectSignature.');
    }
  } on Exception catch (e) {
    logger.e('walletConnector sendCustomRequest Exception .');
    logger.e(e);
    if (e.toString().contains('User denied')) {
      logger.e('User Cancelled Connection Request.');
    }
  }
  logger.e('walletConnectSignature requestResult $walletConnectSignature');
  return walletConnectSignature;
}

Future<bool> signTransactionExample({
  required BuildContext context,
  Function? onProgress,
  required WalletConnect walletConnector,
}) async {
  // This is the json file that defines the NFT, hosted in IPFS
  // see https://docs.rarible.org/asset/creating-an-asset#creating-our-nfts-metadata

  /// Get the next available token id
  onProgress?.call('-> Requesting signTransactionExample using minter address $minter');

  String signature = '';

  onProgress?.call('Calling WalletConnect API to have form signed.');

  signature = await signTransaction(
    context: context,
    walletConnector: walletConnector,
  );
  log('signature signTransactionExample $signature');
  if (signature.isNotEmpty) {
    stringTxnHash = signature;
    visible  = true;
  }

  // We are good unless there was an error message
  return (!signature.contains('Error'));
}

Future<bool> lazyMintExample({
  required BuildContext context,
  Function? onProgress,
  required WalletConnect walletConnector,
}) async {
  // This is the json file that defines the NFT, hosted in IPFS
  // see https://docs.rarible.org/asset/creating-an-asset#creating-our-nfts-metadata
  String uri = "/ipfs/QmVUzkLxEoCRyit8uXAuUoVUgFw1c7Uvz7T4bkGgJUwxcf"; // buffalo metadata

  /// Get the next available token id
  onProgress?.call('-> Requesting next available token ID for collection $collection using minter address $minter');
  tokenId = await getNextTokenId(minter: minter);

  //I/flutter (15000): tokenId = 51853873187524799243313032258623492611584136611923237689466576623960428904484 (0x72a4408da42de870499c1841d0e4a49f864e34ba000000000000000000000024)
  if (tokenId.length < 3) {
    logger.e('First 20 bytes of a tokenId needs to match our minter address.');
    logger.e('* Was the collection contract address generated from a rarible TokenFactory?');
    logger.e(
        '* Is the collection contract address valid for this blockchain?  \n(${blockchainFlavor.name}) $blockExplorer/$collection');
    logger.e('* Does the minter have permissions to create tokens on this collection?');
    return false;
  }
  if (tokenId.startsWith('Error')) {
    // Server error getting a valid token
    return false;
  }
  // rarible.com store requires addresses to be lowercase #gotcha
  // and uses the path to indicate the chain (defaulting to ethereum if blank)
  nftStoreUri = raribleDotCom +
      '/token/' +
      (basePath.contains('polygon') ? 'polygon/' : '') +
      collection.toLowerCase() +
      ':' +
      tokenId.toLowerCase();

  onProgress?.call('tokenId = $tokenId (0x${BigInt.parse(tokenId).toRadixString(16)})');

  // Create lazyMintRequestBody part 1
  // This is the recipe for the NFT, so the contents are more dynamic
  Map<String, dynamic> lazyMintFormJson = {
    "@type": "ERC721",
    "contract": collection,
    "tokenURI": uri,
    "tokenId": tokenId,
    "uri": uri,
    // The end user/minter should verify they are listed as the first creator
    // so they have the ability to sell the Lazy Minted NFT
    "creators": [
      {"account": minter, "value": 10000} // value numbers are not in quotes
    ],
    // The artist and technology partners will likely be listed in royalties
    "royalties": [
      {"account": minter, "value": 2500} // value numbers are not in quotes
    ],
    // To be added after signing
    // "signatures": [signature]
  };

  onProgress?.call('Authoring lazyMintRequest Form.');
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  String prettyPrint = encoder.convert(lazyMintFormJson);
  // logger.i('lazyMintFormJson:\n$prettyPrint\n');

  // Package the form inside a signedTypeData message
  TypedMessage mint721TypedMessage = createMint721TypedMessage(
      collectionChainId: chainId, collectionAddress: collection, lazyMintFormJson: lazyMintFormJson);

  String signature = '';
  String minterPrivateKey = EnvironmentConfig.kExampleMinterPrivateKey;
  /// Sign the typed Data Structure of request
  onProgress?.call('Calling WalletConnect API to have form signed.');

  const message = "My email is john@doe.com - 1537836206101";

  signature = await signTypedDataWithWalletConnect(
    context: context,
    walletConnector: walletConnector,
    typedMessage: mint721TypedMessage,
  );
  log('signature signTypedDataWithWalletConnect $signature');

  /// Build final Lazy Mint Request - add list of signatures
  lazyMintFormJson['signatures'] = [signature];
  //lazyMintFormJson.remove('tokenURI'); // Example code does not include tokenURI

  prettyPrint = encoder.convert(lazyMintFormJson);
  log('lazyMintFormJson\n---\n$prettyPrint\n---');

  String mintStatus = await requestLazyMint(lazyMintFormJson) ?? 'Error: null response from API';

  onProgress?.call('LazyMint completed.  Store link: $nftStoreUri');
  if (basePath.contains('polygon')) {
    // rarible uses the path to indicate a Polygon address from Ethereum
    logger.d('getNftLazyItemById -> ${basePath}v0.1/nft/items/polygon/$collection:$tokenId/lazy');
  } else {
    logger.d('getNftLazyItemById -> ${basePath}v0.1/nft/items/$collection:$tokenId/lazy');
  }
  logger.d('$multichainBaseUrl/v0.1/items/$multichainBlockchain:$collection:$tokenId');
  logger.d('$multichainBaseUrl/v0.1/ownerships/byItem?itemId=$multichainBlockchain:$collection:$tokenId');

  validateLazyMint(collection: collection, tokenId: tokenId);

  // We are good unless there was an error message
  return (!mintStatus.contains('Error'));
}

/// Validate Lazy Mint Item
///
/// Check the NFT has completed processing and the metadata is visible
/// Verify the NFT is not for sale ( See https://github.com/rarible/protocol/issues/338 )
/// https://multichain.redoc.ly/v0.1#operation/getItemById
/// TODO:
/// https://api-staging.rarible.org/v0.1/items/ETHEREUM:0xf565108F208136B1AffD55d19A6236b6b6b9786D:57821959090642343791910250240090585543967286493013648175904625818401167638831
Future<String> validateLazyMint({required String collection, required String tokenId, String? minter}) async {
  Stopwatch stopwatch = Stopwatch();

  String apiUrl = '$multichainBaseUrl/v0.1/items/$multichainBlockchain:$collection:$tokenId';
  logger.d('Reading item details back from Rarible.  apiUrl: $apiUrl');

  var client = http.Client();
  final apiUri = Uri.parse(apiUrl);
  final hostname = apiUri.host;

  stopwatch.start();
  final ipAddress = await InternetAddress.lookup(hostname);
  stopwatch.stop();
  logger.i('${stopwatch.elapsedMilliseconds}ms for DNS lookup of hostname $hostname ($ipAddress)');
  Map<String, dynamic>? meta = null;

  stopwatch.reset();
  stopwatch.start();
  try {
    var response = await client.get(
      Uri.https(apiUri.host.toString(), apiUri.path.toString()),
    );
    stopwatch.stop();
    logger.i('${stopwatch.elapsedMilliseconds}ms for API $apiUri');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      //logger.d('200 ok: $decodedResponse');

      if (decodedResponse.keys.contains('meta')) {
        logger.d('Metadata entry exists!');
        meta = decodedResponse['meta'];
      } else {
        logger.e('200 ok, but missing "meta" entry: $decodedResponse');
      }
    } else {
      var decodedResponse = jsonDecode(response.body);
      logger.e('response: ${response.statusCode}: ${response.reasonPhrase} / ${response.body.toString()}.');
      return 'Error: ${response.statusCode}:${response.reasonPhrase} - ${decodedResponse['message']}.';
    }
  } on SocketException {
    logger.e('SocketException');
    return 'Error: We are unable to initiate communicate with our backend. (SocketException).';
  } on TimeoutException {
    logger.e('TimeoutException');
    return 'Error: Our rarible servers are taking too long to respond. (TimeoutException).';
  } catch (e) {
    logger.e('Error: Ok, we were not expecting this error: $e');
  } finally {
    client.close();
  }
  return (meta != null) ? 'Pass: Metadata exists' : 'Fail: No Metadata';
  // working case  {"id":"ETHEREUM:0x6ede7f3c26975aad32a475e1021d8f6f39c89d82:51853873187524799243313032258623492611584136611923237689466576623960428904598","blockchain":"ETHEREUM","collection":"ETHEREUM:0x6ede7f3c26975aad32a475e1021d8f6f39c89d82","contract":"ETHEREUM:0x6ede7f3c26975aad32a475e1021d8f6f39c89d82","tokenId":"51853873187524799243313032258623492611584136611923237689466576623960428904598","creators":[{"account":"ETHEREUM:0x72a4408da42de870499c1841d0e4a49f864e34ba","value":10000}],"owners":[],"royalties":[],"lazySupply":"0","pending":[],"mintedAt":"2022-04-17T20:51:55.676Z","lastUpdatedAt":"2022-04-14T21:53:25.172Z","supply":"0","meta":{"name":"Buffalo4","description":"It's actually a bison?","attributes":[{"key":"BackgroundColor","value":"bluegreen\n"},{"key":"Eyes","value":"googly"}],"content":[{"@type":"IMAGE","url":"https://austingriffith.com/images/paintings/buffalo.jpg","representation":"ORIGINAL","mimeType":"image/jpeg","size":44104,"width":604,"height":480}],"restrictions":[]},"deleted":true,"auctions":[],"totalStock":"0","sellers":0}0
  // metadata fail {"id":"ETHEREUM:0x6ede7f3c26975aad32a475e1021d8f6f39c89d82:51853873187524799243313032258623492611584136611923237689466576623960428905332","blockchain":"ETHEREUM","collection":"ETHEREUM:0x6ede7f3c26975aad32a475e1021d8f6f39c89d82","contract":"ETHEREUM:0x6ede7f3c26975aad32a475e1021d8f6f39c89d82","tokenId":"51853873187524799243313032258623492611584136611923237689466576623960428905332","creators":[{"account":"ETHEREUM:0x72a4408da42de870499c1841d0e4a49f864e34ba","value":10000}],"owners":[],"royalties":[],"lazySupply":"1","pending":[],"mintedAt":"2022-04-17T21:05:43.527Z","lastUpdatedAt":"2022-04-17T20:40:48.770Z","supply":"1","deleted":false,"auctions":[],"totalStock":"0","sellers":0}
}

/// Delete Lazy Minted Item
///  [collection] the address of the Lazy Mint compatible ERC-721 contract
///  [minter] the address of the primary creator who will sign the later
///           Lazy Mint request
///
///  Ethereum API nft-collection-controller:generateNftTokenId
///  https://ethereum-api.rarible.org/v0.1/doc#operation/generateNftTokenId
Future<String> lazyDelete({required String collection, required String tokenId, required String minter}) async {
  Stopwatch stopwatch = Stopwatch();
  String apiUrl = '${basePath}v0.1/nft/items/$collection:$tokenId/lazy/delete';
  logger.d('Requesting deletion of tokenId: $tokenId from collection $collection using endpoint $apiUrl.');

  // We need to prove we are the owner of the NFT by using a personal signed note
  String lazyDeleteRequest = 'I would like to burn my $tokenId item.';
  String personalSignature = '';

  String minterPrivateKey = EnvironmentConfig.kExampleMinterPrivateKey;


  Map<String, dynamic> lazyDeleteForm = {
    "creators": [minter],
    "signatures": [personalSignature]
  };

  logger.d(jsonEncode(lazyDeleteForm));

  var client = http.Client();
  final apiUri = Uri.parse(apiUrl);
  final hostname = apiUri.host;

  stopwatch.start();
  final ipAddress = await InternetAddress.lookup(hostname);
  stopwatch.stop();
  logger.i('${stopwatch.elapsedMilliseconds}ms for DNS lookup of hostname $hostname ($ipAddress)');

  stopwatch.reset();
  stopwatch.start();
  try {
    var response = await client.post(Uri.https(apiUri.host.toString(), apiUri.path.toString()),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(lazyDeleteForm));
    stopwatch.stop();
    logger.i('${stopwatch.elapsedMilliseconds}ms for API $apiUri');
    log(response.body);
    if (response.statusCode == 204) {
      logger.d('successful delete. status code: ${response.statusCode}');
    } else {
      var decodedResponse = jsonDecode(response.body);
      logger.e('response: ${response.statusCode}: ${response.reasonPhrase} / ${response.body.toString()}.');
      return 'Error: ${response.statusCode}:${response.reasonPhrase} - ${decodedResponse['message']}.';
    }
  } on SocketException {
    logger.e('SocketException');
    return 'Error: We are unable to initiate communicate with our backend. (SocketException).';
  } on TimeoutException {
    logger.e('TimeoutException');
    return 'Error: Our rarible servers are taking too long to respond. (TimeoutException).';
    //} catch (e) {
    //  logger.e('Error: Ok, we were not expecting this error: $e');
  } finally {
    client.close();
  }
  return 'TODO';
}

class _WalletConnectThirdpartyState extends State<WalletConnectThirdparty> with WidgetsBindingObserver {
  String statusMessage = 'Initialized';
  String _displayUri = ''; // QR Code for OpenConnect but not used

  // final Web3Client ethereum;
  // final EthereumWalletConnectProvider provider;

  /// Initialize Global Settings based on blockchain selected
  ///
  /// [blockchain] User selected blockchain
  Future<void> init({BlockchainFlavor blockchain = BlockchainFlavor.rinkeby, bool preserveMinterAddress = false}) async {
    blockchainFlavor = blockchain;
    basePath = basePathMap[blockchain] ?? '';
    chainId = chainIdMap[blockchain] ?? 0;
    collection = assetContractErc721Map[blockchain] ?? ''; // rarible.com default contract addresses
    multichainBaseUrl =
    ({BlockchainFlavor.rinkeby, BlockchainFlavor.ropsten, BlockchainFlavor.mumbai}.contains(blockchain))
        ? 'https://api-staging.rarible.org'
        : 'https://api.rarible.org';
    multichainBlockchain = multiChainBlockchainMap[blockchain] ?? '';

    // WalletConnect may have provided a updated minter address
    if (!preserveMinterAddress) {
      minter = EnvironmentConfig.kExampleMinterAddress;
    }
    raribleDotCom = raribleDotComMap[blockchain] ?? '';
    blockExplorer = blockExplorerMap[blockchain] ?? '';
    tokenId = 'Not Yet Requested\n\n';

    logger.d('Initialized Rarible on ${describeEnum(blockchain)} (chain ID: $chainId) with API basePath $basePath');
    logger.d('multichain baseUrl $multichainBaseUrl with blockchain $multichainBlockchain');
    // Poylygon collections have an additional path
    if (basePath.contains('polygon')) {
      logger.d('Collection Address: $collection - $raribleDotCom/collection/polygon/$collection}');
    } else {
      logger.d('Collection Address: $collection - $raribleDotCom/collection/$collection}');
    }
    logger.d('Minter Wallet address: $minter - $blockExplorer/$minter');
    logger.d('Faucet URL: ${faucetMap[blockchain] ?? 'unknown'}');
  }

  Future<void> initWalletConnect() async {
    // Wallet Connect Session Storage - So we can persist connections
    final sessionStorage = WalletConnectSecureStorage();
    final session = await sessionStorage.getSession();

    // Create a connector
    walletConnect = WalletConnect(
      // TODO: V1 performance issues - consider rolling your own bridge
      bridge: 'https://bridge.walletconnect.org',
      session: session,
      sessionStorage: sessionStorage,
      clientMeta: const PeerMeta(
        name: 'Flutter Rarible Demo',
        description: 'Flutter Rarible Protocol Demo App',
        url: 'https://www.gto.io',
        icons: [('/favicon.png')],
      ),
    );

    // Did we restore a session?
    if (session != null) {
      logger.d(
          "WalletConnect - Restored  v${session.version} session: ${session.accounts.length} account(s), bridge: ${session.bridge} connected: ${session.connected}, clientId: ${session.clientId}");

      if (session.connected) {
        logger.d(
            'WalletConnect - Attempting to reuse existing connection for chainId ${session.chainId} and wallet address ${session.accounts[0]} key ${session.key}.');
        setState(() {
          minter = session.accounts[0];
          chainId = session.chainId;
          blockchainFlavor = BlockchainFlavorExtention.fromChainId(chainId);
        });

        if (minter != null) {
          // https://rinkeby.infura.io/v3/a93948fb99514781b77253f1e6df7133
          // https://matic-mumbai.chainstacklabs.com
          // final rpcURL = 'https://rinkeby.infura.io/v3/a93948fb99514781b77253f1e6df7133';
          // var httpClient = Client();
          _client = Web3Client(session.rpcUrl, Client());
          EthereumWalletConnectProvider provider = EthereumWalletConnectProvider(walletConnect);
          _credentials = WalletConnectEthereumCredentials(provider: provider);


          await Provider.of<WalletProvider>(context, listen: false).initializeFromMetaMask(provider,session.accounts[0]);

          // // Test Firebase auth
          // final authProviderFirebase = Provider.of<AuthProvider>(context, listen: false).signInAnonymously();
          // debugPrint('authProviderFirebase signInAnonymously ');
          // debugPrint(authProviderFirebase.toString());
          // await Provider.of<AuthProvider>(context, listen: false).signInWithCredential(credential: _credentials);

          // await Provider.of<WalletProvider>(context, listen: false)
          //     .initializeFromKey(_keyController.text);
          // //
          Provider.of<AppProvider>(context, listen: false).initialize();
          final stateProvider = await Provider.of<AppProvider>(context, listen: false).state;
          // await Provider.of<AppProvider>(context, listen: false).initialize();

          logger.w('state AppProvider $stateProvider.');
          // logger.w('state unauthenticated ${AppState.unauthenticated}.');
          // logger.w('state authenticated - ${AppState.loaded}.');

          // yourContract = YourContract(address: contractAddr, client: client);

          // You can now call rpc methods. This one will query the amount of Ether you own
          // EtherAmount balance = ethClient.getBalance(credentials.address);
          // print(balance.getValueInUnit(EtherUnit.ether));

          logger.w('Credentials web3dart - ${_credentials}.');
          // scheduleMicrotask(() {
          //   Navigation.popAllAndPush(
          //     context,
          //     screen: const CreateWalletScreen(),
          //   );
          // });
        }
      }
    } else {
      logger.w('WalletConnect - No existing sessions.  User needs to connect to a wallet.');
    }

    walletConnect.registerListeners(
      onConnect: (status) {
        // Status is updated, but session.peerinfo is not yet available.
        logger.d(
            'WalletConnect - onConnect - Established connection with  Wallet app: ${walletConnect.session.peerMeta?.name} -${walletConnect.session.peerMeta?.description}');

        setState(() {
          statusMessage =
          'WalletConnect session established with ${walletConnect.session.peerMeta?.name} - ${walletConnect.session.peerMeta?.description}.';
        });

        // Did the user select a new chain?
        if (chainId != status.chainId) {
          logger.d(
              'WalletConnect - onConnect - Selected blockchain has changed: chainId: $chainId <- ${status.chainId})');
          setState(() {
            chainId = status.chainId;
            blockchainFlavor = BlockchainFlavorExtention.fromChainId(chainId);
          });
        }

        // Did the user select a new wallet address?
        if (minter != status.accounts[0]) {
          logger.d('WalletConnect - onConnect - Selected wallet has changed: minter: $minter <- ${status.accounts[0]}');
          setState(() {
            minter = status.accounts[0];
          });
        }
      },
      onSessionUpdate: (status) {
        // What information is available?
        //print('WalletConnect - Updated session. $status');

        logger.d(
            'WalletConnect - onSessionUpdate - Wallet ${walletConnect.session.peerMeta?.name} - ${walletConnect.session.peerMeta?.description}');

        setState(() {
          statusMessage =
          'WalletConnect - SessionUpdate received with chainId ${status.chainId} and account ${status.accounts[0]}.';
        });

        // Did the user select a new chain?
        if (chainId != status.chainId) {
          logger.d(
              'WalletConnect - onSessionUpdate - Selected blockchain has changed: chainId: $chainId <- ${status.chainId}');
          setState(() {
            chainId = status.chainId;
            blockchainFlavor = BlockchainFlavorExtention.fromChainId(chainId);
          });
        }

        // Did the user select a new wallet address?
        if (minter != status.accounts[0]) {
          logger.d(
              'WalletConnect - onSessionUpdate - Selected wallet has changed: minter: $minter <- ${status.accounts[0]}');
          setState(() {
            minter = status.accounts[0];
          });
        }
      },
      onDisconnect: () async {
        logger.d('WalletConnect - onDisconnect - minter: $minter <- "Please Connect Wallet"');
        setState(() {
          minter = 'Please Connect Wallet';
          statusMessage = 'WalletConnect session disconnected.';
        });
        await initWalletConnect();
      },
    );
  }

  Future<void> createWalletConnectSession(BuildContext context) async {
    // Create a new session
    if (walletConnect.connected) {
      statusMessage =
      'Already connected to ${walletConnect.session.peerMeta?.name} \n${walletConnect.session.peerMeta?.description}\n${walletConnect.session.peerMeta?.url}';
      logger.d(
          'createWalletConnectSession - Ignored because WalletConnect Already connected to ${walletConnect.session.peerMeta?.name} with user address: $minter, chainId $chainId. Ignored.');
      return;
    }

    // IOS users will need to be prompted which wallet to use.
    if (Platform.isIOS) {
      List<WalletConnectRegistryListing> listings = await readWalletRegistry(limit: 4);

      await showModalBottomSheet(
        context: context,
        builder: (context) {
          return showIOSWalletSelectionDialog(context, listings, setWalletListing);
        },
        isScrollControlled: true,
        isDismissible: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      );
    }

    logger.d('createWalletConnectSession');
    SessionStatus session;
    try {
      session = await walletConnect.createSession(
          chainId: 1,
          onDisplayUri: (uri) async {
            setState(() {
              _displayUri = uri;
              logger.d('_displayUri updated with $uri');
            });

            // Open any registered wallet via wc: intent
            bool? result;

            // IOS users have already chosen wallet, so customize the launcher
            if (Platform.isIOS) {
              uri = walletListing.mobile.universal + '/wc?uri=${Uri.encodeComponent(uri)}';
            }
            // Else
            // - Android users will choose their walled from the OS prompt

            logger.d('launching uri: $uri');
            try {
              result = await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
              if (result == false) {
                // launch alternative method
                logger.e('Initial launchuri failed. Fallback launch with forceSafariVC true');
                result = await launchUrl(Uri.parse(uri));
                if (result == false) {
                  logger.e('Could not launch $uri');
                }
              }
              if (result) {
                setState(() {
                  statusMessage = 'Launched wallet app, requesting session.';
                });
              }
            } on PlatformException catch (e) {
              if (e.code == 'ACTIVITY_NOT_FOUND') {
                logger.w('No wallets available - do nothing!');
                setState(() {
                  statusMessage = 'ERROR - No WalletConnect compatible wallets found.';
                });
                return;
              }
              logger.e('launch returned $result');
              logger.e('Unexpected PlatformException error: ${e.message}, code: ${e.code}, details: ${e.details}');
            } on Exception catch (e) {
              logger.e('launch returned $result');
              logger.e('url launcher other error e: $e');
            }
          });
    } catch (e) {
      logger.e('Unable to connect - killing the session on our side.');
      statusMessage = 'Unable to connect - killing the session on our side.';
      walletConnect.killSession();
      return;
    }
    if (session.accounts.isEmpty) {
      statusMessage = 'Failed to connect to wallet.  Bridge Overloaded? Could not Connect?';

      // wc:f54c5bca-7712-4187-908c-9a92aa70d8db@1?bridge=https%3A%2F%2Fz.bridge.walletconnect.org&key=155ca05ffc2ab197772a5bd56a5686728f9fcc2b6eee5ffcb6fd07e46337888c
      logger.e('Failed to connect to wallet.  Bridge Overloaded? Could not Connect?');
    }
  }

  Future<String> signTransactionMetaMask(SessionStatus session) async {
    final sender = EthereumAddress.fromHex(session.accounts[0]);

    final transaction = Transaction(
      to: sender,
      from: sender,
      gasPrice: EtherAmount.inWei(BigInt.one),
      maxGas: 100000,
      value: EtherAmount.fromUnitAndValue(EtherUnit.finney, 1),
    );

    // EthereumWalletConnectProvider provider = EthereumWalletConnectProvider(walletConnect);
    // final credentials = WalletConnectEthereumCredentials(provider: provider);

    // Sign the transaction
    final txBytes = await _client.sendTransaction(_credentials, transaction);

    // // Kill the session
    // walletConnect.killSession();

    return txBytes;
  }

  final TextEditingController _keyController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _checkTxnHash() async {
    var etherscan = 'https://github.com/huynhduyman/m2e';
    if (basePath.contains('polygon')) {
      etherscan = 'https://mumbai.polygonscan.com/tx/$stringTxnHash';
    } else {
      etherscan = 'https://rinkeby.etherscan.io/tx/$stringTxnHash';
    }
    log(etherscan);
    if (await launch(etherscan)) {}
  }

  @override
  void initState() {
    super.initState();
    // Register observer so we can see app lifecycle changes.
    WidgetsBinding.instance!.addObserver(this);
    init(blockchain: BlockchainFlavor.mumbai);
    initWalletConnect();
  }

  /// The wallet connect client, sometimes loses the webSocket connection when the app is suspended
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DateFormat dateFormat = DateFormat("HH:mm:ss");
    String dateString = dateFormat.format(DateTime.now());

    logger.d("$dateString AppLifecycleState: ${state.toString()}.");

    if (state == AppLifecycleState.resumed && mounted) {
      // If we have a configured connection but the websocket is down try once to reconnect
      if (walletConnect.connected && walletConnect.bridgeConnected == false) {
        logger.w('$dateString  Wallet connected, but transport is down.  Attempt to recover.');
        walletConnect.reconnect();
      }
    }

    if (state == AppLifecycleState.resumed) {
      // If we have a configured connection but the websocket is down try once to reconnect
      if (walletConnect.connected && walletConnect.bridgeConnected == true) {
        logger.w('$dateString  Wallet connected, ');
        setState(() {
          textWalletConnect = 'Wallet connected';
        });
      }
    }

  }

  _userInfo() async {
    await Provider.of<AppProvider>(context, listen: false).initialize();
    Navigation.push(
      context,
      screen: const EditUserInfoScreen(),
    );
  }

  _homescreen() async {
    await Provider.of<AppProvider>(context, listen: false).initialize();
    Navigation.popAllAndPush(context, screen: const SplashScreen());
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
    // Remove observer for app lifecycle changes.
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: space2x),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CustomAppBar(),
              SizedBox(height: rh(60)),
              Center(
                child: UpperCaseText(
                  'Welcome to nfts.',
                  style: Theme.of(context).textTheme.headline2,
                ),
              ),

              SizedBox(height: rh(space4x)),

              //HELPER TEXT
              Text(
                'We need your wallet access in order to sign Transactions and interact with Blockchain.',
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),

              DropdownButton(
                dropdownColor: Theme.of(context).cardColor,

                value: describeEnum(blockchainFlavor),
                items: <String>['ropsten', 'rinkeby', 'ethMainNet', 'mumbai', 'polygonMainNet', 'unknown']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) async {
                  switch (value) {
                    case 'ropsten':
                      blockchainFlavor = BlockchainFlavor.ropsten;
                      break;
                    case 'rinkeby':
                      blockchainFlavor = BlockchainFlavor.rinkeby;
                      break;
                    case 'ethMainNet':
                      blockchainFlavor = BlockchainFlavor.ethMainNet;
                      break;
                    case 'mumbai':
                      blockchainFlavor = BlockchainFlavor.mumbai;
                      break;
                    case 'polygonMainNet':
                      blockchainFlavor = BlockchainFlavor.polygonMainNet;
                      break;
                  }
                  await init(blockchain: blockchainFlavor, preserveMinterAddress: true);
                  setState(() {
                    // // redundant - shouldn't need these
                    // blockchainFlavor = blockchainFlavor;
                    // chainId = chainId;
                    // basePath = basePath;
                    // collection = collection;
                  });
                },
              ),

              SizedBox(height: rh(space3x)),

              ElevatedButton.icon(
                icon: Container(
                  child: Image.asset(
                      'assets/images/WalletConnect.png',
                      // width: rf(100),
                      height: rh(50)
                    // style: Theme.of(context).textTheme.headline5,
                  ),
                ),
                onPressed: () {
                  createWalletConnectSession(context);
                  if (walletConnect.connected) {
                    setState(() {
                      statusMessage = 'Wallet connected';
                      textWalletConnect = 'Wallet connected';
                    });
                  }
                },
                label: Text(textWalletConnect),
              ),

              ElevatedButton(
                onPressed: () {
                  if (walletConnect.connected) {
                    logger.d('Killing session');
                    walletConnect.killSession();
                    setState(() {
                      statusMessage = 'Wallet Disconnected';
                      textWalletConnect = 'Please Connect Wallet';
                    });
                  }
                },
                child: const Text('Disconnect Wallet'),
              ),

              ElevatedButton(
                child: const Text('Mint NFT'),
                onPressed: (() async {
                  logger.d('Button Pressed');

                  if (!walletConnect.connected && EnvironmentConfig.kExampleMinterAddress.isEmpty) {
                    setState(() {
                      statusMessage = 'Connect to wallet first!';
                    });
                    return;
                  }
                  await lazyMintExample(
                      context: context,
                      walletConnector: walletConnect,
                      onProgress: ((String v) {
                        logger.d(v);
                        setState(() {
                          statusMessage = v;
                        });
                      }));
                }),
              ),

              ElevatedButton(
                child: const Text('signTransaction'),
                onPressed: (() async {
                  logger.d('Button Pressed');

                  if (!walletConnect.connected) {
                    setState(() {
                      statusMessage = 'Connect to wallet first!';
                    });
                    return;
                  }
                  await signTransactionExample(
                      context: context,
                      walletConnector: walletConnect,
                      onProgress: ((String v) {
                        logger.d(v);
                        setState(() {
                          statusMessage = v;
                        });
                      }));
                }),
              ),

              Buttons.flexible(
                width: double.infinity,
                context: context,
                text: 'User Info',
                onPressed: _userInfo,
              ),

              SizedBox(height: rh(space3x)),

              Buttons.flexible(
                width: double.infinity,
                context: context,
                text: 'Home',
                onPressed: _homescreen,
              ),

              Visibility(
                visible: visible,
                child:
                Buttons.text(
                  context: context,
                  text: 'Check Txn Hash',
                  onPressed: _checkTxnHash,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
