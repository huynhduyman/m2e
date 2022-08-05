import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/animations/fade_animation.dart';
import '../../core/animations/scale_animation.dart';
import '../../locator.dart';
import '../../provider/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nfts/core/services/notification_service.dart';
import '../splash_screen/splash_screen.dart';

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../provider/wallet_provider.dart';
import '../../core/services/wallet_service.dart';
import '../../config/config.dart';

class NetworkConfirmationScreen extends StatefulWidget {
  const NetworkConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<NetworkConfirmationScreen> createState() =>
      _NetworkConfirmationScreenState();
}

class _NetworkConfirmationScreenState extends State<NetworkConfirmationScreen> {
  final NotificationService _notificationService = NotificationService();

  _openUrl(String lastTxHash, BuildContext context) async {
    String url = '';
    if (urlBlockchainscan.contains('polygon')) {
      url = 'https://mumbai.polygonscan.com/tx/$lastTxHash';
    } else {
      url = 'https://rinkeby.etherscan.io/tx/$lastTxHash';
    }
    debugPrint(url);

    if (await launch(url)) {}

    // if (await canLaunch(url)) {
    //   await launch(url);
    //   await Future.delayed(const Duration(seconds: 2));
    //   _skipForNow(context);
    // }
  }

  _skipForNow(context) async {
    await Provider.of<AppProvider>(context, listen: false).initialize();

    Navigation.popAllAndPush(context, screen: const SplashScreen());
  }

  void _showNotification(Map<String, dynamic> strNotification) async {
    print(strNotification);
    // List<Data> dataList = strNotification.map((i) => Data.fromJson(i)).toList();
    await _notificationService.showNotifications(strNotification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WalletProvider>(builder: (context, provider, child) {
        debugPrint('_NetworkConfirmationScreenState provider.state: ${provider.state}');
        debugPrint('sent transation provider.state: ${provider.state}');
        debugPrint('Retrieve transation lastTxHash: ${provider.lastTxHash}');
        final lastTxHash = provider.lastTxHash;
        // Provider.of<WalletService>(context, listen: false).setLastTxHash('');
        // Call Local notification Service
        final strNotification =
            '{"title": "NFTS - sent transation", "body": "Congratulations! Transaction successful with Txn Hash $lastTxHash ", "payload": "String payload", "extra": null}';
        _showNotification(jsonDecode(strNotification));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: rh(60)),
            ScaleAnimation(
              duration: const Duration(milliseconds: 750),
              child: SvgPicture.asset(
                'assets/images/tick.svg',
                width: rf(100),
              ),
            ),
            SizedBox(height: rh(20)),

            Center(
              child: UpperCaseText(
                'Congratulations,',
                style: Theme.of(context).textTheme.headline2,
              ),
            ),
            SizedBox(height: rh(space1x)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: space2x),
              child: FadeAnimation(
                duration: const Duration(milliseconds: 5000),
                intervalStart: 0.85,
                child: UpperCaseText(
                  'Transaction successful with Txn Hash:',
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1!
                      .copyWith(height: 2),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: rh(20)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: space2x),
              child: FadeAnimation(
                duration: const Duration(milliseconds: 5000),
                intervalStart: 0.85,
                child: UpperCaseText(
                  lastTxHash,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1!
                      .copyWith(height: 2),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: rh(20)),
            Buttons.flexible(
              width: double.infinity,
              context: context,
              text: 'Check Txn Hash',
              onPressed: () =>
                  _openUrl(lastTxHash, context),
            ),

            SizedBox(height: rh(space2x)),
            FadeAnimation(
              duration: const Duration(milliseconds: 5000),
              intervalStart: 0.85,
              child: Buttons.text(
                context: context,
                text: 'Go Home',
                onPressed: () {
                  Navigation.pop(context);

                  Timer(const Duration(seconds: 16), () {
                    locator<AppProvider>().initialize();
                  });
                },
              ),
            ),

          ],
        );
        // if (provider.state == WalletState.success) {
        //   // Provider.of<AppProvider>(context, listen: false).initialize();
        //   // scheduleMicrotask(() {
        //   //   Navigation.pop(context);
        //   // });
        //   debugPrint('sent transation provider.state: ${provider.state}');
        //   debugPrint('Retrieve transation lastTxHash: ${provider.lastTxHash}');
        //   final lastTxHash = provider.lastTxHash;
        //   // Provider.of<WalletService>(context, listen: false).setLastTxHash('');
        //   return Column(
        //     crossAxisAlignment: CrossAxisAlignment.center,
        //     children: [
        //       SizedBox(height: rh(60)),
        //       ScaleAnimation(
        //         duration: const Duration(milliseconds: 750),
        //         child: SvgPicture.asset(
        //           'assets/images/tick.svg',
        //           width: rf(100),
        //         ),
        //       ),
        //       SizedBox(height: rh(20)),
        //
        //       Center(
        //         child: UpperCaseText(
        //           'Congratulations,',
        //           style: Theme.of(context).textTheme.headline2,
        //         ),
        //       ),
        //       SizedBox(height: rh(20)),
        //       Buttons.flexible(
        //         width: double.infinity,
        //         context: context,
        //         text: 'Check Txn Hash',
        //         onPressed: () =>
        //             _openUrl(lastTxHash, context),
        //       ),
        //
        //       SizedBox(height: rh(space6x)),
        //       FadeAnimation(
        //         duration: const Duration(milliseconds: 5000),
        //         intervalStart: 0.85,
        //         child: Buttons.text(
        //           context: context,
        //           text: 'process transaction in background',
        //           onPressed: () {
        //             Navigation.pop(context);
        //
        //             Timer(const Duration(seconds: 16), () {
        //               locator<AppProvider>().initialize();
        //             });
        //           },
        //         ),
        //       ),
        //       SizedBox(height: rh(space1x)),
        //       Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: space2x),
        //         child: FadeAnimation(
        //           duration: const Duration(milliseconds: 5000),
        //           intervalStart: 0.85,
        //           child: UpperCaseText(
        //             '*When you Skip, It may take time to reflect changes.',
        //             style: Theme.of(context)
        //                 .textTheme
        //                 .subtitle1!
        //                 .copyWith(height: 2),
        //             textAlign: TextAlign.center,
        //           ),
        //         ),
        //       ),
        //     ],
        //   );
        //
        // }
        // else {
        //   return Column(
        //     crossAxisAlignment: CrossAxisAlignment.center,
        //     children: [
        //       SizedBox(height: rh(60)),
        //       Image.asset(
        //         'assets/images/loading1.gif',
        //       ),
        //       SizedBox(height: rh(space6x)),
        //       UpperCaseText(
        //         'Please wait',
        //         style: Theme.of(context).textTheme.headline2,
        //       ),
        //       SizedBox(height: rh(space2x)),
        //       Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: space2x),
        //         child: UpperCaseText(
        //           'we are Confirming your transaction \n Allow upto 20 seconds',
        //           style:
        //           Theme.of(context).textTheme.headline6!.copyWith(height: 2),
        //           textAlign: TextAlign.center,
        //         ),
        //       ),
        //       SizedBox(height: rh(space6x)),
        //       FadeAnimation(
        //         duration: const Duration(milliseconds: 5000),
        //         intervalStart: 0.85,
        //         child: Buttons.text(
        //           context: context,
        //           text: 'process transaction in background',
        //           onPressed: () {
        //             Navigation.pop(context);
        //
        //             Timer(const Duration(seconds: 16), () {
        //               locator<AppProvider>().initialize();
        //             });
        //           },
        //         ),
        //       ),
        //       SizedBox(height: rh(space1x)),
        //       Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: space2x),
        //         child: FadeAnimation(
        //           duration: const Duration(milliseconds: 5000),
        //           intervalStart: 0.85,
        //           child: UpperCaseText(
        //             '*When you Skip, It may take time to reflect changes.',
        //             style: Theme.of(context)
        //                 .textTheme
        //                 .subtitle1!
        //                 .copyWith(height: 2),
        //             textAlign: TextAlign.center,
        //           ),
        //         ),
        //       ),
        //     ],
        //   );
        // }
        // return Column(
        //   crossAxisAlignment: CrossAxisAlignment.center,
        //   children: [
        //     SizedBox(height: rh(60)),
        //     Image.asset(
        //       'assets/images/loading1.gif',
        //     ),
        //     SizedBox(height: rh(space6x)),
        //     UpperCaseText(
        //       'Please wait',
        //       style: Theme.of(context).textTheme.headline2,
        //     ),
        //     SizedBox(height: rh(space2x)),
        //     Padding(
        //       padding: const EdgeInsets.symmetric(horizontal: space2x),
        //       child: UpperCaseText(
        //         'we are Confirming your transaction \n Allow upto 20 seconds',
        //         style:
        //             Theme.of(context).textTheme.headline6!.copyWith(height: 2),
        //         textAlign: TextAlign.center,
        //       ),
        //     ),
        //     SizedBox(height: rh(space6x)),
        //     FadeAnimation(
        //       duration: const Duration(milliseconds: 5000),
        //       intervalStart: 0.85,
        //       child: Buttons.text(
        //         context: context,
        //         text: 'process transaction in background',
        //         onPressed: () {
        //           Navigation.pop(context);
        //
        //           Timer(const Duration(seconds: 16), () {
        //             locator<AppProvider>().initialize();
        //           });
        //         },
        //       ),
        //     ),
        //     SizedBox(height: rh(space1x)),
        //     Padding(
        //       padding: const EdgeInsets.symmetric(horizontal: space2x),
        //       child: FadeAnimation(
        //         duration: const Duration(milliseconds: 5000),
        //         intervalStart: 0.85,
        //         child: UpperCaseText(
        //           '*When you Skip, It may take time to reflect changes.',
        //           style: Theme.of(context)
        //               .textTheme
        //               .subtitle1!
        //               .copyWith(height: 2),
        //           textAlign: TextAlign.center,
        //         ),
        //       ),
        //     ),
        //   ],
        // );
      }),
    );
  }
}
