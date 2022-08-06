import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/animations/animations.dart';
import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../provider/app_provider.dart';
import '../../provider/auth_provider.dart';
import '../create_wallet_screen/create_wallet_screen.dart';
import '../user_screen/sign_in_user_info_screen.dart';
import '../user_screen/sign_up_user_info_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  _navigate(Widget screen) async {
    // Navigation.pushReplacement(context, screen: screen);
    scheduleMicrotask(() {
      Navigation.pushReplacement(context, screen: screen);
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    // final stateAuthProvider = Provider.of<AuthProvider>(context, listen: false);
    // // final stateAuthProvider = Provider.of<AuthProvider>(context, listen: false);
    // debugPrint('SplashScreen addListener Firebase auth:${stateAuthProvider.state}');
    // stateAuthProvider.addListener(() {
    //   debugPrint('SplashScreen addListener Firebase auth:${stateAuthProvider.state}');
    //   if (stateAuthProvider.state == AuthState.empty) {
    //
    //     scheduleMicrotask(() {
    //       Navigation.pushReplacement(
    //         context,
    //         screen: const SignUpUserInfoScreen(),
    //       );
    //     });
    //     // _navigate(const SignUpUserInfoScreen());
    //   }
    // });


    // await Provider.of<WalletProvider>(context, listen: false).balance;

    // Consumer<AuthProvider>(builder: (context, authProvider, child) {
    //   debugPrint('Consumer AuthProvider');
    //   if (authProvider.state == AuthState.empty) {
    //     debugPrint('AuthProvider authProvider ${authProvider.state}');
    //     return const SignUpUserInfoScreen();
    //   } else {
    //     return const WalletConnectThirdparty();
    //
    //   }
    //   return const CreateWalletScreen();
    // });
  }

  @override
  void dispose() {
    _keyController.dispose();
    // stateAuthProvider.cancel();
    // stateAuthProvider.dispose();
    super.dispose();
  }

  double width = 100;
  double height = 100;

  @override
  Widget build(BuildContext context) {

    // StreamBuilder(
    //     stream: FirebaseService().authStateChanges,
    //     builder: (context, snapshot) {
    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const Center(child: CircularProgressIndicator());
    //       } else if (snapshot.hasData) {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const WalletConnectThirdparty();
    //       } else if (snapshot.hasError) {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const Center(child: Text('Something went wrong'));
    //       } else {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const SignUpUserInfoScreen();
    //       }
    //
    //     }
    // );


    // final stateAuthProvider = Provider.of<AuthProvider>(context, listen: false);
    // debugPrint(' Firebase auth:${stateAuthProvider.state}');
    // debugPrint(stateAuthProvider.isAuthenticated.toString());
    // final authProvider = Provider.of<FirebaseService>(context, listen: false);

    // // authStateChanges
    // FirebaseAuth.instance.authStateChanges().listen((user) {
    //   if (user == null) {
    //     debugPrint('User is currently signed out!');
    //     // _navigate(const SignUpUserInfoScreen());
    //   } else {
    //     debugPrint('User is signed in!');
    //     debugPrint(user.toString());
    //     // Navigation.pushReplacement(
    //     //   context,
    //     //   name: 'tabs_screen',
    //     // );
    //   }
    // });

    // userChanges streams: your listeners will receive the current User, or null if no user is authenticated:
    // To check if the user is signed in from anywhere in the app, use
    // if (FirebaseAuth.instance.currentUser != null) {
    //   debugPrint('User is signed in!');
    //   debugPrint(FirebaseAuth.instance.currentUser.toString());
    // }



    // final appProvider = Provider.of<AppProvider>(context, listen: false);
    // appProvider.addListener(() {
    //   debugPrint('appProvider addListener ${appProvider.state}');
    //   if (appProvider.state == AppState.unauthenticated) {
    //     _navigate(const CreateWalletScreen());
    //     // return SignUpUserInfoScreen();
    //
    //     // _navigate(const SignUpUserInfoScreen());
    //   }
    // });

    // StreamBuilder(
    //     stream: FirebaseService().authStateChanges,
    //     builder: (context, snapshot) {
    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const Center(child: CircularProgressIndicator());
    //       } else if (snapshot.hasData) {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const CreateWalletScreen();
    //       } else if (snapshot.hasError) {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const Center(child: Text('Something went wrong'));
    //       } else {
    //         debugPrint(' StreamBuilder :${snapshot.toString()}');
    //         return const SignUpUserInfoScreen();
    //       }
    //
    //     }
    // )


    return Scaffold(
      backgroundColor: Colors.white,
      body:
      Consumer<AuthProvider>(builder: (context, authProvider, child) {
        debugPrint('Consumer AuthProvider');
        debugPrint(authProvider.isSignedIn.toString());
        if (authProvider.isSignedIn == false) {
          return const SignInUserInfoScreen();
        }
        // debugPrint(authProvider.state.toString());
        //
        // debugPrint(authProvider.getUser?.email.toString());
        if (authProvider.state == AuthState.empty) {
          return const SignInUserInfoScreen();
        }
        else if (authProvider.state == AuthState.error) {
          return const SignInUserInfoScreen();
        }
        // else if (authProvider.state == AuthState.loaded) {
        //
        // }
        else {

        // }
        // switch (authProvider.state) {
        //   case AuthState.empty:
        //     return const SignInUserInfoScreen();
        //   case AuthState.error:
        //     return const SignInUserInfoScreen();
        //   case AuthState.loading:
        //     // TODO: Handle this case.
        //     return const SignInUserInfoScreen();
        //   case AuthState.success:
        //     // TODO: Handle this case.
        //     return const SignInUserInfoScreen();
        //   case AuthState.loaded:
        //     // TODO: Handle this case.
            return
              Consumer<AppProvider>(builder: (context, provider, child) {

                debugPrint('provider.state ${provider.state}');
                if (provider.state == AppState.unauthenticated) {
                  debugPrint('provider.state ${provider.state}');
                  return const SignUpUserInfoScreen();
                  // _navigate(const SignUpUserInfoScreen());
                }
                else if (provider.state == AppState.notwalletconnected) {
                  _navigate(const CreateWalletScreen());
                  // return SignUpUserInfoScreen();

                  // _navigate(const SignUpUserInfoScreen());
                } else if (provider.state == AppState.loaded) {
                  // _navigate(const TestMaticScreen());
                  scheduleMicrotask(() {
                    Navigation.push(
                      context,
                      name: 'tabs_screen',
                    );
                  });
                  // return TabsScreen();
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.fastOutSlowIn,
                        padding: const EdgeInsets.all(
                          space4x,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(space1x),
                          color: Theme
                              .of(context)
                              .colorScheme
                              .background,
                        ),
                        // alignment: Alignment.center,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              UpperCaseText(
                                'nfts',
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .headline3!
                                    .copyWith(
                                  fontSize: rf(24),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      bottom: rh(170),
                      left: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: ScaleAnimation(
                          duration: const Duration(milliseconds: 750),
                          child: FadeAnimation(
                            duration: const Duration(milliseconds: 750),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: rf(95),
                              // style: Theme.of(context).textTheme.headline5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: rh(60),
                      left: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: SlideAnimation(
                          begin: const Offset(-100, 0),
                          duration: const Duration(milliseconds: 450),
                          child: FadeAnimation(
                            duration: const Duration(milliseconds: 450),
                            child: UpperCaseText(
                              'Just a slide away',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .subtitle1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              });

        }
        // return const CreateWalletScreen();
      }),
      // StreamBuilder(
      //     stream: FirebaseService().authStateChanges,
      //     builder: (context, snapshot) {
      //       if (snapshot.connectionState == ConnectionState.waiting) {
      //         debugPrint(' StreamBuilder :${snapshot.toString()}');
      //         return const Center(child: CircularProgressIndicator());
      //       } else if (snapshot.hasData) {
      //         debugPrint(' StreamBuilder snapshot hasData :${snapshot.toString()}');
      //         return
      //
      //       } else if (snapshot.hasError) {
      //         debugPrint(' StreamBuilder :${snapshot.toString()}');
      //         return const Center(child: Text('Something went wrong'));
      //       } else {
      //         debugPrint(' StreamBuilder :${snapshot.toString()}');
      //         return const SignUpUserInfoScreen();
      //       }
      //
      //     }
      // ),

    );
  }
}
