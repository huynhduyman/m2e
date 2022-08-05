import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../provider/wallet_provider.dart';
import '../test_matic_screen/test_matic_screen.dart';
import '../wallet_init_screen/wallet_init_screen.dart';
import '../wallet_connect_thirdparty/wallet_connect_thirdparty.dart';


class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({Key? key}) : super(key: key);

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  //Navigate to Wallet Init Screen
  _walletconnect() {
    Navigation.push(
      context,
      screen: const WalletConnectThirdparty(),
    );
  }

  _navigate() {
    Navigation.push(
      context,
      screen: const WalletInitScreen(),
    );
  }

  _createWallet() async {
    await Provider.of<WalletProvider>(context, listen: false).createWallet();

    Navigation.push(
      context,
      screen: const TestMaticScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      debugPrint('CreateWalletScreen User is signed in!');
      debugPrint(FirebaseAuth.instance.currentUser?.uid);
      final user = FirebaseAuth.instance.currentUser!;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: space2x),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: rh(200)),
            // Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 10),
            //   child: Text(
            //     "User:${user.email!}",
            //     style: const TextStyle(
            //       color: Colors.white,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            // ),
            Center(
              child: UpperCaseText(
                'Choose Wallet Type',
                style: Theme.of(context).textTheme.headline2,
              ),
            ),

            SizedBox(height: rh(space3x)),
            CustomOutlinedButton(
              width: double.infinity,
              text: 'Connect my wallet',
              onPressed: _walletconnect,
            ),
            SizedBox(height: rh(space3x)),
            Buttons.flexible(
              width: double.infinity,
              context: context,
              text: 'Import a private Key',
              onPressed: _navigate,
            ),
            SizedBox(height: rh(space3x)),
            CustomOutlinedButton(
              width: double.infinity,
              text: 'Create a new wallet',
              onPressed: _createWallet,
            ),
          ],
        ),
      ),
    );
  }
}
