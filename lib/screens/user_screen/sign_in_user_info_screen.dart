import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nfts/provider/auth_provider.dart';
import 'package:nfts/screens/user_screen/forgot_password_info_screen.dart';
import 'package:nfts/screens/user_screen/sign_up_user_info_screen.dart';
import 'package:provider/provider.dart';

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../tabs_screen/tabs_screen.dart';

class SignInUserInfoScreen extends StatefulWidget {
  const SignInUserInfoScreen({Key? key}) : super(key: key);

  @override
  State<SignInUserInfoScreen> createState() => _SignInUserInfoScreenState();
}

class _SignInUserInfoScreenState extends State<SignInUserInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String errMessage = '';

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  // final TextEditingController _textEditingController = TextEditingController();

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

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // await Provider.of<WalletProvider>(context, listen: false).balance;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      errMessage = '';
      final status = await Provider.of<AuthProvider>(context, listen: false).signIn(email: _emailController.text.trim(), password: _passwordController.text.trim());

      if (status == null) {
        setState(() {
          errMessage = 'Error Signined.';
        });
        Fluttertoast.showToast(msg: 'Error Signined.');
        errMessage = 'error';
      }
      if (status != _emailController.text) {
        setState(() {
          errMessage = 'Error $status.';
        });
        Fluttertoast.showToast(msg: 'Error. $status');
        errMessage = 'error';
      }
      if (errMessage.isEmpty) {
        // Fluttertoast.showToast(msg: 'Signined. $status');
        TextInput.finishAutofillContext();
        final email = _emailController.text;

        _scaffoldMessenger('Signned with $email');
        _navigate(const TabsScreen());
      }
    }
  }

  void _scaffoldMessenger(String status) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(status),
      ));
  }

  _navigate(Widget screen) async {
    // Navigation.pushReplacement(context, screen: screen);
    scheduleMicrotask(() {
      Navigation.pushReplacement(context, screen: screen);
    });
  }

  void togglePasswordVisibility() => setState(() => isHidden = !isHidden);
  void onListen() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: space2x),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const CustomAppBar(),
              SizedBox(height: rh(space6x)),
              // SizedBox(height: rh(space1x)),
              Center(
                child: UpperCaseText(
                  'SignIn to nfts.',
                  style: Theme.of(context).textTheme.headline2,
                ),
              ),
              SizedBox(height: rh(space4x)),
              //INPUT
              Form(
                key: _formKey,
                  child: AutofillGroup(
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
                            autofillHints: const [AutofillHints.email],
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
                              isHidden ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
                              onPressed: togglePasswordVisibility,
                            ),
                            prefix: const Icon(Icons.lock),
                            autofillHints: const [AutofillHints.password],
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              child: const Text('Forgot Password?'),
                              onPressed: () {
                                // _navigate(const ForgotPassWordInfoScreen());
                                Navigation.push(
                                  context,
                                  screen: const ForgotPassWordInfoScreen(),
                                );
                              },
                            ),
                          ),
                          // SizedBox(height: rh(space2x)),
                        ],
                    ),
                  ),
              ),
              // SizedBox(height: rh(space1x)),
              //ACTION BUTTONS
              Buttons.expanded(
                context: context,
                text: 'Sign in the world of NFT',
                onPressed: _submit,
              ),
              SizedBox(height: rh(space3x)),
              GestureDetector(
                onTap: () =>
                    _navigate(const SignUpUserInfoScreen()),
                child: Text(
                  'Don\'t have an account ? touch to Sign Up',
                  style: Theme.of(context).textTheme.headline2,

                  // style: TextStyle(
                  //   decoration: TextDecoration.underline,
                  // ),

                  // decoration: TextDecoration.underline,
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
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Color(0xFF1A1818),
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
                    // onTap: () => Navigation.popAllAndPush(
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
                            // Navigation.popAllAndPush(context, screen: const SplashScreen());
                          },
                        )
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
