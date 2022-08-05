import 'dart:async';
import 'dart:convert';
// import 'dart:developer';
import 'dart:io';
// import 'dart:typed_data';

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

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../provider/wallet_provider.dart';
import '../../constants.dart';
import '../../models/wallet_connect_registry.dart';
import '../../core/widgets/wallet_connect_dialog/wallet_connect_dialog.dart';

// class EnvironmentConfig {
//   static const kExampleMinterAddress = String.fromEnvironment('MINTER_ADDRESS');
// }

class WalletUserInfoScreen extends StatefulWidget with WidgetsBindingObserver {
  const WalletUserInfoScreen({Key? key}) : super(key: key);
  @override
  State<WalletUserInfoScreen> createState() => _WalletUserInfoScreenState();
}

// Global Settings

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

class _WalletUserInfoScreenState extends State<WalletUserInfoScreen> with WidgetsBindingObserver {
  String statusMessage = 'Initialized';
  String _displayUri = ''; // QR Code for OpenConnect but not used

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
  bool visible = false;
  String? stringTxnHash;
  String? nftStoreUri;
  String textWalletConnect = 'WalletConnect';

  // final Web3Client ethereum;
  // final EthereumWalletConnectProvider provider;

  @override
  void initState() {
    super.initState();
    // Register observer so we can see app lifecycle changes.
    WidgetsBinding.instance.addObserver(this);
    init(blockchain: BlockchainFlavor.mumbai);
    initWalletConnect();
  }

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
    // if (!preserveMinterAddress) {
    //   minter = EnvironmentConfig.kExampleMinterAddress;
    // }
    minter = '';
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
    // logger.d('Minter Wallet address: $minter - $blockExplorer/$minter');
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
          "WalletConnect - Restored  version ${session.version} , bridge: ${session.bridge} connected: ${session.connected}, clientId: ${session.clientId}");

      if (session.connected) {
        logger.d(
            'connected WalletConnect for chainId ${session.chainId} and wallet address ${session.accounts[0]}.');
        setState(() {
          minter = session.accounts[0];
          chainId = session.chainId;
          blockchainFlavor = BlockchainFlavorExtention.fromChainId(chainId);
          Future.delayed(const Duration(seconds: 3));
          textWalletConnect = 'Wallet connected';
        });

        if (minter.isNotEmpty) {
          Web3Client(session.rpcUrl, Client());
          EthereumWalletConnectProvider provider = EthereumWalletConnectProvider(walletConnect);
          WalletConnectEthereumCredentials(provider: provider);

          // Call Init WalletProvider
          await Provider.of<WalletProvider>(context, listen: false).initializeFromMetaMask(provider,session.accounts[0]);
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
              uri = '${walletListing.mobile.universal}/wc?uri=${Uri.encodeComponent(uri)}';
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

  final TextEditingController _keyController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
    // Remove observer for app lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
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

              SizedBox(height: rh(space2x)),

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

              // SizedBox(height: rh(space3x)),

              ElevatedButton.icon(
                icon: Image.asset(
                    'assets/images/WalletConnect.png',
                    // width: rf(100),
                    height: rh(50)
                  // style: Theme.of(context).textTheme.headline5,
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
                      statusMessage = 'Disconnected';
                      textWalletConnect = 'Please Connect Wallet';
                    });
                  }
                },
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
