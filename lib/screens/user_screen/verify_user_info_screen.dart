import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nfts/provider/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';

class VerifyUserInfoScreen extends StatefulWidget with WidgetsBindingObserver {
  const VerifyUserInfoScreen({Key? key}) : super(key: key);

  @override
  State<VerifyUserInfoScreen> createState() => _VerifyUserInfoScreen();
}

class _VerifyUserInfoScreen extends State<VerifyUserInfoScreen> with WidgetsBindingObserver {
  String errMessage = '';
  String statusMessage = 'Initialized';
  bool _isEmailVerified = false;
  String _email = '';
  late Timer _timer;
  // final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  Uint8List? bytes;
  // User? user;
  // late AuthProvider user;

  @override
  void initState() {
    super.initState();
    // Register observer so we can see app lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    //Get Authenticated user
    refreshFirebaseUser();

    // if (_isEmailVerified == false) {
    //   _startEmailVerificationTimer();
    // }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // await Provider.of<WalletProvider>(context, listen: false).balance;
  }

  /// sometimes loses the webSocket connection when the app is suspended
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    debugPrint('state = $state');

    DateFormat dateFormat = DateFormat("HH:mm:ss");
    String dateString = dateFormat.format(DateTime.now());
    debugPrint("$dateString AppLifecycleState: ${state.toString()}.");

    if (state == AppLifecycleState.resumed && mounted) {
      // If we have a configured connection but the websocket is down try once to reconnect
      refreshFirebaseUser();
      if (_isEmailVerified == true) {
        setState(() {
        });
        // timer?.cancel();
      }
      // else {
      //   if (!timer.isActive) _startEmailVerificationTimer();
      // }
    }

    if (state == AppLifecycleState.resumed) {
      // If we have a configured connection but the websocket is down try once to reconnect
      refreshFirebaseUser();
      if (_isEmailVerified == true) {
        setState(() {
        });



        // timer?.cancel();
      }
      // else {
      //   if (!timer.isActive) _startEmailVerificationTimer();
      // }
    }
  }

  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed && !firebaseUser.isEmailVerified)
  //     refreshFirebaseUser().then((value) => setState(() {}));
  //   super.didChangeAppLifecycleState(state);
  // }

  // _startEmailVerificationTimer() {
  //   timer = Timer.periodic(Duration(seconds: 5), (Timer _) {
  //     // user = context.read<AuthenticationService>().reloadCurrentUser();
  //     Provider.of<AuthProvider>(context, listen: false).sendEmailVerification();
  //     if (_isEmailVerified == true) {
  //       setState(() {
  //         _isEmailVerified = true;
  //       });
  //       timer.cancel();
  //     }
  //   });
  // }

  @override
  void dispose() {
    _emailController.dispose();
    if (_timer.isActive) {
      _timer.cancel();
    }
    // Remove observer for app lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refreshFirebaseUser() async {
    final firebaseUser = Provider.of<AuthProvider>(context, listen: false);
    _email = (firebaseUser.getUser?.email)!;
    final isEmailVerified = await firebaseUser.isEmailVerified();
    // await firebaseUser.getUser?.reload();
    if (isEmailVerified == true) {
      setState(() {
        _isEmailVerified = true;
      });
      _timer.cancel();
      _back();
      _scaffoldMessenger('Account verification successful!');
    }
  }

  _back() {
    Navigation.pop(context);
  }


  Future<void> sendEmailVerification() async {
    debugPrint(_isEmailVerified.toString());
    await Provider.of<AuthProvider>(context, listen: false).sendEmailVerification();
  }

  void _scaffoldMessenger(String status) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(status),
      ));
  }

  Future<void> _submit() async {
    try {
      await sendEmailVerification();
      debugPrint('sent Verify success');
      _scaffoldMessenger('Sent a link to the your email $_email');
      refreshFirebaseUser();
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer _) async {
        await refreshFirebaseUser();
      });

    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> sendEmailVerification: $e');
      Fluttertoast.showToast(msg: 'Error. $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          debugPrint(authProvider.state.toString());
          if (authProvider.state == AuthState.loading) {
          }
          if ( _isEmailVerified == true) {
            Future.delayed(const Duration(seconds: 3));
            // return _back();

          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomAppBar(),
                SizedBox(height: rh(space1x)),
                SizedBox(height: rh(space1x)),
                Center(
                  child: UpperCaseText(
                    'Verification Account!.',
                    style: Theme.of(context).textTheme.headline2,
                  ),
                ),
                Text(
                  'Verify account by sending a link to the your email: $_email',
                  style: Theme.of(context).textTheme.caption,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: rh(space4x)),
                //INPUT
                SizedBox(height: rh(space3x)),
                //ACTION BUTTONS
                Buttons.expanded(
                  context: context,
                  text: 'Verify',
                  // onPressed: isLoading ? null : _submit,


                  onPressed: _submit,
                  // onPressed: () {
                  //   if (isLoading == false) {
                  //     _submit;
                  //   }
                  // }
                  // onPressed: () async {
                  //   await Future.delayed(const Duration(milliseconds: 500), () {
                  //     _submit;
                  //     setState(() {
                  //     });
                  //   });
                  // },
                ),

                SizedBox(height: rh(space3x)),
              ],
            ),
          );
        },
      ),
    );
  }
}
