import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';

import 'package:http/http.dart'; //You can also import the browser version
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../provider/wallet_provider.dart';
import '../../provider/app_provider.dart';
import 'widgets/transaction_fee_widget.dart';

import '../../constants.dart';
import '../../models/wallet_connect_registry.dart';
import '../../core/widgets/wallet_connect_dialog/wallet_connect_dialog.dart';

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

class ConfirmationScreen extends StatefulWidget with WidgetsBindingObserver {
  const ConfirmationScreen({
    Key? key,
    this.onConfirmation,
    this.isAutoMated = false,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.action,
  }) : super(key: key);

  final String image;
  final String title;
  final String subtitle;
  final String action;

  final bool isAutoMated;
  final VoidCallback? onConfirmation;

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> with WidgetsBindingObserver {

  String statusMessage = 'Initialized';
  String _displayUri = ''; // QR Code for OpenConnect but not used

  final TextEditingController _keyController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
          _client = Web3Client(session.rpcUrl, Client());
          EthereumWalletConnectProvider provider = EthereumWalletConnectProvider(walletConnect);
          _credentials = WalletConnectEthereumCredentials(provider: provider);
          //
          // await Provider.of<WalletProvider>(context, listen: false).initializeFromMetaMask(provider,session.accounts[0]);

          // await Provider.of<WalletProvider>(context, listen: false)
          //     .initializeFromKey(_keyController.text);
          // //
          // final stateProvider = await Provider.of<AppProvider>(context, listen: false).state;
          // // await Provider.of<AppProvider>(context, listen: false).initialize();
          //
          // logger.w('state AppProvider $stateProvider.');
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
      await init();
      // await initWalletConnect();
      await autoWalletConnectSession();
      await init();
      setState(() {});
      return initWalletConnect();
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

  // auto connect wallet
  Future<void> autoWalletConnectSession() async {
    // Create a new session
    if (walletConnect.connected) {
      statusMessage =
      'Already connected to ${walletConnect.session.peerMeta?.name} \n${walletConnect.session.peerMeta?.description}\n${walletConnect.session.peerMeta?.url}';
      logger.d(
          'createWalletConnectSession - Ignored because WalletConnect Already connected to ${walletConnect.session.peerMeta?.name} with user address: $minter, chainId $chainId. Ignored.');
      return;
    }

    // IOS users will need to be prompted which wallet to use.

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
      // var uri = Uri.https(
      //   'registry.walletconnect.com',
      //   '/api/v1/wallets',
      //   queryParameters,
      // );
      // debugPrint(uri.toString());
      response = await client.get(
        Uri.https(
          'registry.walletconnect.com',
          '/api/v1/wallets',
          queryParameters,
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      // debugPrint(response.statusCode.toString());

      if (response.statusCode == 200) {
         // log(response.body);
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
         // log(decodedResponse!['listings'].toString());

        if (decodedResponse!['listings'] != null) {
          // Present user with list of supported wallets (IOS)
          // log(decodedResponse!['listings'].values.toString());

          for (Map<String, dynamic> entry in decodedResponse!['listings'].values) {
            // log(entry.toString());
            if (entry.values.isNotEmpty) {
              listings.add(WalletConnectRegistryListing.fromMap(entry));
            }

            logger.d('Processing ${listings.last.name}');
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

  //Confirm Transaction
  _confirmTransaction() async {
    if (widget.isAutoMated) {
      // final provider = Provider.of<WalletProvider>(context, listen: false);
      // provider.sendTransaction(provider.transactionInfo!);

      logger.d('Calling WalletConnect API to have form signed.');
      // String lastTxHash = await signTransaction();
      // For signing requests for a connected wallet, only provide the existing session id and version number.
      String walletConnectTopicVersion = 'wc:${walletConnect.session.handshakeTopic}@${walletConnect.session.version}';
      String walletConnectUri = '';
      String lastTxHash = '';

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

      // // // If the wallet isn't already opened, give it a change to startup
      // sleep(const Duration(milliseconds: 1000));

      logger.e('walletConnector sendCustomRequest.');

      // Ask WalletConnect wallet to sign the request
      final provider = Provider.of<WalletProvider>(context, listen: false);
      // logger.e('walletConnector sendCustomRequest : sendTransactionWithThirdParty transactionInfo: ');
      // debugPrint('transactionInfo: ${provider.transactionInfo.toString()}');
      lastTxHash = await provider.sendTransactionWithThirdParty(_credentials,provider.transactionInfo!);
      // provider.sendTransactionWithThirdParty(_credentials,provider.transactionInfo!);
      logger.e('lastTxHash $lastTxHash .');
      logger.d('signature signTransaction $lastTxHash');
      if (lastTxHash.isEmpty) {
        return;
      }
      if (lastTxHash.toString().contains('User canceled') || lastTxHash.toString().contains('User rejected')) {
        logger.d('User rejected signature signTransaction');
        provider.getTransactionFee(provider.transactionInfo!);
        return;
      }

      if (lastTxHash.toString().contains('error') || lastTxHash.toString().contains('32000')) {
        logger.d('signature signTransaction Error: $lastTxHash');
        provider.getTransactionFee(provider.transactionInfo!);
        return;
      }



      logger.d('provider state: ${provider.state}');

      // Provider.of<AppProvider>(context, listen: false).initialize();

      if (widget.onConfirmation != null) widget.onConfirmation!();
    }
  }

  Future<String> signTransaction() async {

    // For signing requests for a connected wallet, only provide the existing session id and version number.
    String walletConnectTopicVersion = 'wc:${walletConnect.session.handshakeTopic}@${walletConnect.session.version}';
    String walletConnectUri = '';
    String lastTxHash = '';

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

    // // // If the wallet isn't already opened, give it a change to startup
    // sleep(const Duration(milliseconds: 1000));

    logger.e('walletConnector sendCustomRequest.');

    // Ask WalletConnect wallet to sign the request
    final provider = Provider.of<WalletProvider>(context, listen: false);
    // logger.e('walletConnector sendCustomRequest : sendTransactionWithThirdParty transactionInfo: ');
    // debugPrint('transactionInfo: ${provider.transactionInfo.toString()}');
    lastTxHash = await provider.sendTransactionWithThirdParty(_credentials,provider.transactionInfo!);
    // provider.sendTransactionWithThirdParty(_credentials,provider.transactionInfo!);
    logger.e('lastTxHash $lastTxHash .');

    return lastTxHash;
  }

  /// Updates global walletListing so subsequent requests can be directed to the wallet
  void setWalletListing(WalletConnectRegistryListing listing) {
    walletListing = listing;
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: space2x),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Consumer<WalletProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomAppBar(title: widget.action),
                        SizedBox(height: rh(space4x)),

                        //NETWORK INFO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _INFOTILE(
                              label: 'Network',
                              value: 'Polygon Testnet Mumbai',
                            ),
                            _INFOTILE(
                              //Confirm Transaction
                              label: 'Balance',
                              value: '${formatBalance(provider.balance)} MATIC',
                            ),
                          ],
                        ),

                        SizedBox(height: rh(space2x)),
                        const Divider(),
                        SizedBox(height: rh(space2x)),

                        // Center(
                        //   child: UpperCaseText(
                        //     widget.action,
                        //     style:
                        //         Theme.of(context).textTheme.headline6!.copyWith(
                        //               letterSpacing: 2.5,
                        //             ),
                        //   ),
                        // ),
                        // SizedBox(height: rh(18)),

                        //Input
                        CollectionListTile(
                          image: widget.image,
                          title: widget.title,
                          subtitle: widget.subtitle,
                          // subtitle: widget.action,
                          isSubtitleVerified: true,
                          showFav: false,
                        ),

                        SizedBox(height: rh(space3x)),
                        const Divider(),
                        SizedBox(height: rh(space3x)),

                        //FORM TO INFO
                        // if (provider.transactionInfo != null)
                        //   TransactionInfo(
                        //     transactionInfo: provider.transactionInfo!,
                        //   ),

                        //FEE INFO
                        if (provider.state == WalletState.loading)
                          const Center(
                            child: EmptyWidget(text: 'Loading ...'),
                          )
                        else if (provider.state == WalletState.error)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: space2x,
                              vertical: space2x,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Theme.of(context).errorColor,
                            ),
                            child: UpperCaseText(
                              provider.errMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5!
                                  .copyWith(
                                    color: Colors.white,
                                    height: 1.8,
                                  ),
                            ),
                          )
                        else
                          TransactionFeeWidget(
                            transactionInfo: provider.transactionInfo!,
                            gasInfo: provider.gasInfo!,
                            totalAmount: provider.totalAmount,
                            maticPrice: provider.maticPrice,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            //SLIDE TO CONFIRM
            Container(
              margin: const EdgeInsets.only(bottom: space6x),
              child:
                  Consumer<WalletProvider>(builder: (context, provider, child) {
                return ConfirmationSlider(
                  width: rw(300),
                  stickToEnd:
                      provider.state == WalletState.loading ? false : true,
                  backgroundColor: Theme.of(context).colorScheme.background,
                  foregroundColor: provider.state == WalletState.loading ||
                          provider.state == WalletState.error
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).primaryColor,
                  textStyle: Theme.of(context).textTheme.subtitle1,
                  text: provider.state == WalletState.error
                      ? 'Error Occured'
                      : 'SLIDE TO CONFIRM',
                  onConfirmation: provider.state == WalletState.loading ||
                          provider.state == WalletState.error
                      ? () {}
                      : _confirmTransaction,
                  shadow: BoxShadow(
                    blurRadius: 15,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 2),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _INFOTILE extends StatelessWidget {
  const _INFOTILE({Key? key, required this.label, required this.value})
      : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UpperCaseText(
          label,
          // style: Theme.of(context).textTheme.overline,
          style: Theme.of(context).textTheme.subtitle2,
        ),
        SizedBox(height: rh(6)),
        UpperCaseText(
          value,
          // style: Theme.of(context).textTheme.bodyText2,
          style: Theme.of(context).textTheme.bodyText2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

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

class EnvironmentConfig {
  static const kExampleMinterAddress = String.fromEnvironment('MINTER_ADDRESS');
  static const kExampleMinterPrivateKey = String.fromEnvironment('MINTER_PRIVATE_KEY');
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
