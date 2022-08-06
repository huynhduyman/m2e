import 'dart:async';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nfts/provider/auth_provider.dart';
import 'package:nfts/screens/user_screen/sign_in_user_info_screen.dart';
import 'package:provider/provider.dart';

import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';

class ForgotPassWordInfoScreen extends StatefulWidget {
  const ForgotPassWordInfoScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPassWordInfoScreen> createState() => _ForgotPassWordInfoScreen();
}

class _ForgotPassWordInfoScreen extends State<ForgotPassWordInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String errMessage = '';

  final TextEditingController _emailController = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      errMessage = '';
      final status = await Provider.of<AuthProvider>(context, listen: false).resetPassword(email: _emailController.text.trim());
      debugPrint('sent resetPassword success');
      // Fluttertoast.showToast(msg: 'Congratulations, your account has been successfully created.');
      if (status == null) {
        AwesomeDialog(
          context: context,
          animType: AnimType.SCALE,
          dialogType: DialogType.SUCCES,
          body: const Center(child: Text(
            'Password forgot email sent!',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),),
          title: 'Password forgot email sent',
          desc:   'sent ',
          btnOkOnPress: () {
            _navigate(const SignInUserInfoScreen());
          },
        ).show();
      } else {
        Fluttertoast.showToast(msg: 'Error. $status');
      }


      // if (status == null) {
      //   setState(() {
      //     errMessage = 'Error Signined.';
      //   });
      //   Fluttertoast.showToast(msg: 'Error Signined.');
      //   errMessage = 'error';
      // }
      // if (status != _emailController.text) {
      //   setState(() {
      //     errMessage = 'Error $status.';
      //   });
      //   Fluttertoast.showToast(msg: 'Error. $status');
      //   errMessage = 'error';
      // }
      // if (errMessage.isEmpty) {
      //   Fluttertoast.showToast(msg: 'Signined. $status');
      //   _navigate(const TabsScreen());
      // }
    }
  }

  _navigate(Widget screen) async {
    // Navigation.pushReplacement(context, screen: screen);
    scheduleMicrotask(() {
      Navigation.pushReplacement(context, screen: screen);
    });
  }


  Uint8List? bytes;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // await Provider.of<WalletProvider>(context, listen: false).balance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: space2x),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomAppBar(),
              SizedBox(height: rh(space1x)),
              SizedBox(height: rh(space1x)),
              Center(
                child: UpperCaseText(
                  'Forgot Password!.',
                  style: Theme.of(context).textTheme.headline2,
                ),
              ),
              Text(
                'Password resets by sending a reset password link to the your email',
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: rh(space4x)),
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
                      suffix: const Icon(Icons.email),
                    ),
                    SizedBox(height: rh(space2x)),
                  ],
                ),
              ),
              SizedBox(height: rh(space3x)),
              //ACTION BUTTONS
              Buttons.expanded(
                context: context,
                text: 'Reset Password',
                onPressed: _submit,
              ),
              SizedBox(height: rh(space3x)),
            ],
          ),
        ),
      ),
    );
  }
}
