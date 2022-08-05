import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nfts/provider/auth_provider.dart';
import 'package:nfts/screens/user_screen/sign_in_user_info_screen.dart';
import 'package:provider/provider.dart';

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../create_wallet_screen/create_wallet_screen.dart';
import '../splash_screen/splash_screen.dart';
import '../tabs_screen/tabs_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class SignUpUserInfoScreen extends StatefulWidget {
  const SignUpUserInfoScreen({Key? key}) : super(key: key);

  @override
  State<SignUpUserInfoScreen> createState() => _SignUpUserInfoScreenState();
}

class _SignUpUserInfoScreenState extends State<SignUpUserInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String errMessage = '';

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  bool isHidden = true;
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(onListen);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailController.removeListener(onListen);
    super.dispose();
  }

  void togglePasswordVisibility() => setState(() => isHidden = !isHidden);

  void onListen() => setState(() {});

  void _submit() async {
    errMessage = '';
    if (_formKey.currentState!.validate()) {
      debugPrint('Signup user');
      final status = await Provider.of<AuthProvider>(context, listen: false).signUp(email: _emailController.text, password: _passwordController.text);
      debugPrint('String Signup user $status success');
      if (status == null) {
        Fluttertoast.showToast(msg: 'Error Signup.');
        errMessage = 'error1';
      }
      if (status.toString().trim() != _emailController.text.trim()) {
        Fluttertoast.showToast(msg: 'Error. $status');
        errMessage = 'error2';
      }

      debugPrint(errMessage);
      if (errMessage.isEmpty) {
        debugPrint('Signup user success');
        // Fluttertoast.showToast(msg: 'Congratulations, your account has been successfully created.');
        AwesomeDialog(
          context: context,
          animType: AnimType.SCALE,
          dialogType: DialogType.SUCCES,
          body: const Center(child: Text(
            'Congratulations, your account has been successfully created.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),),
          title: 'Congratulations',
          desc:   'your account has been successfully created',
          btnOkOnPress: () {
            _navigate(const TabsScreen());
            // Navigation.popAllAndPush(
            //   context,
            //   screen: const TabsScreen(),
            // );
          },
        ).show();
      }
    }
  }

  _navigate(Widget screen) async {
    scheduleMicrotask(() {
      Navigation.pushReplacement(context, screen: screen);
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // await Provider.of<WalletProvider>(context, listen: false).balance;
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder(
    //     stream: FirebaseAuth.instance.authStateChanges(),
    //     builder: (BuildContext context, AsyncSnapshot snapshot) {
    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //         debugPrint('snapshot.connectionState');
    //         return const Center(child: CircularProgressIndicator());
    //       } else if (snapshot.hasData) {
    //         debugPrint('snapshot.hasData');
    //         return _navigate(const CreateWalletScreen());
    //       } else if (snapshot.hasError) {
    //         debugPrint('snapshot Something went wrong');
    //         return const Center(child: Text('Something went wrong'));
    //       } else {
    //         debugPrint('snapshot SignUpUserInfoScreen');
    //         return _navigate(const SignUpUserInfoScreen());
    //       }
    //
    //     }
    // );
    return
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/images/fitness3.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.95), BlendMode.dstATop),
          ),
        ),
        child: Scaffold(

          backgroundColor: Colors.transparent,
          body: Container(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: space2x),

              child: SingleChildScrollView(

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const CustomAppBar(),

                    SizedBox(height: rh(space6x)),
                    Center(
                      child: UpperCaseText(
                        'Welcome to nfts.',
                        style: Theme.of(context).textTheme.headline2,
                      ),
                    ),

                    SizedBox(height: rh(space4x)),

                    Center(
                      child: UpperCaseText(
                        'SignUp Page',
                        style: Theme.of(context).textTheme.headline2,
                      ),
                    ),
                    Text(
                      'By signing up, you will receive emails about CoinDesk product updates, events and marketing and you agree to our terms of services and privacy policy.',
                      style: Theme.of(context).textTheme.caption,
                      textAlign: TextAlign.center,
                    ),

//INPUT
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: rh(space2x)),
                          CustomTextFormField(
                            controller: _emailController,
                            labelText: 'Email',
                            validator: emailValidator,
                            textInputType: TextInputType.emailAddress,
                            prefix: const Icon(Icons.mail),
                            suffix: _emailController.text.isEmpty
                                ? Container(width: 0)
                                : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _emailController.clear(),
                            ),
                          ),
                          SizedBox(height: rh(space2x)),
                          CustomTextFormField(
                            controller: _passwordController,
                            labelText: 'Password',
                            validator: validator,
                            textInputType: TextInputType.visiblePassword,
                            obscureText: isHidden,
                            suffix: IconButton(
                              icon:
                              isHidden ? const Icon(Icons.visibility_off) : Icon(Icons.visibility),
                              onPressed: togglePasswordVisibility,
                            ),
                            prefix: Icon(Icons.lock),
                          ),
                          SizedBox(height: rh(space2x)),
                        ],
                      ),
                    ),

                    SizedBox(height: rh(space3x)),
                    //ACTION BUTTONS
                    Buttons.expanded(
                      context: context,
                      text: 'Sign up the world of NFT',
                      onPressed: _submit,
                    ),
                    SizedBox(height: rh(space3x)),

                    GestureDetector(
                      onTap: () =>
                          _navigate(const SignInUserInfoScreen()),


                      child: Text(
                        'Already have an account ? touch SignIn now',
                        style: Theme.of(context).textTheme.headline2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: rh(space3x)),
                    Row(
                      children: const <Widget>[
                        Expanded(
                          child: Divider(
                            color: Color(0xFFD9D9D9),
                            height: 1.5,
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "OR SIGN IN WITH",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0xFFA11212),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: rh(space3x)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => _navigate(const SignInUserInfoScreen()),
                          child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: const Color(0xFFD9D9D9),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Buttons.icon(
                                context: context,
                                svgPath: 'assets/images/gmail.svg',
                                // right: 12,
                                semanticLabel: 'Back',
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _navigate(const SignInUserInfoScreen()),
                          child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: const Color(0xFFD9D9D9),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Buttons.icon(
                                context: context,
                                svgPath: 'assets/images/twitter.svg',
                                // right: 12,
                                semanticLabel: 'Back',
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                          ),
                        ),
                        GestureDetector(
                          // onTap: () => Navigation.push(
                          //   context,
                          //   screen: const SignInUserInfoScreen(),
                          // ),
                          child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: const Color(0xFFD9D9D9),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Buttons.icon(
                                context: context,
                                svgPath: 'assets/images/google.svg',
                                // right: 12,
                                semanticLabel: 'Back',
                                onPressed: () {
                                  final status = Provider.of<AuthProvider>(context, listen: false).signInWithGoogle();
                                  debugPrint('AuthProvider with signInWithGoogle ${status.toString()}');
                                  // Navigation.push(context, screen: const SplashScreen());
                                },
                              )
                          ),
                        ),
                      ],
                    ),




                    // Center(
                    //   child: Buttons.text(
                    //     context: context,
                    //     text: 'Already have an account ?, Signin now',
                    //     onPressed: _signinNow,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),);

  }
}


