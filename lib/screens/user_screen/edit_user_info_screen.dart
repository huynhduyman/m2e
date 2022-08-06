import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nfts/provider/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../core/services/image_picker_service.dart';
import '../../core/utils/utils.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../provider/wallet_provider.dart';
import '../tabs_screen/tabs_screen.dart';

class EditUserInfoScreen extends StatefulWidget {
  const EditUserInfoScreen({Key? key}) : super(key: key);

  @override
  State<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends State<EditUserInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _websiteController = TextEditingController();

  final TextEditingController _twitterController = TextEditingController();

  String? _pickedImagePath;
  _pickImage() async {
    //Pick Image
    final image = await ImagePickerService.pickImage();
    // Image.

    if (image != null) {
      _pickedImagePath = image.path;
      debugPrint(_pickedImagePath);

      setState(() {});
    }
  }

  _submit() {
    String email = 'man.huynh@gmail.com';
    String password = 'passs123456';
    Provider.of<AuthProvider>(context, listen: false).signUp(email: email, password: password);
    if (_formKey.currentState!.validate()) {
      Navigation.popAllAndPush(
        context,
        screen: const TabsScreen(),
      );
    }
  }

  _skipForNow() {
    // Provider.of<AuthProvider>(context, listen: false).signInAnonymously();
    // AuthService(FirebaseAuth.instance).logInAnonymously();
    String email = 'man.huynh@gmail.com';
    String password = 'passs123456';
    // Provider.of<AuthProvider>(context, listen: false).signInAnonymously();
    // Provider.of<AuthProvider>(context, listen: false).signUp(email: email, password: password);
    Provider.of<AuthProvider>(context, listen: false).signIn(email: email, password: password);
    // AuthService(FirebaseAuth.instance).login(email, password);
    // AuthService(FirebaseAuth.instance).signUp(email, password);
    Navigation.popAllAndPush(
      context,
      screen: const TabsScreen(),
    );
  }

  Uint8List? bytes;

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _twitterController.dispose();
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

              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: rf(200),
                    height: rf(200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(space1x),
                      color: Theme.of(context).colorScheme.surface,
                      // image: DecorationImage(
                      //     image: _pickedImagePath == null
                      //         ? AssetImage()
                      //         : FileImage(_pickedImagePath),
                      //     fit: BoxFit.cover
                      // ),


                      image: _pickedImagePath == null
                          ? null
                          : DecorationImage(
                              image: FileImage(File(_pickedImagePath!)),
                              // image: AssetImage(_pickedImagePath!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: _pickedImagePath == null
                        ? UpperCaseText(
                            '+ Add image',
                            style: Theme.of(context).textTheme.headline4,
                          )
                        : null,
                  ),
                ),
              ),

              //USER ADDRESS INFO
              Consumer<WalletProvider>(
                builder: (context, provider, child) {
                  return Column(
                    children: [
                      SizedBox(height: rh(space4x)),
                      DataTile(
                        label: 'Public Address',
                        value: provider.address.hex,

                        icon: Iconsax.copy,
                        onIconPressed: () => copy(provider.address.hex),
                        // '0x7E104F0dcB499eBcC8b680C2B83f3f35250445dE',
                      ),
                      SizedBox(height: rh(space3x)),
                      DataTile(
                        label: 'Wallet Balance',
                        value: '${formatBalance(provider.balance)} MATIC',
                        // '10 MAT - \$38 ',
                      ),
                      SizedBox(height: rh(space2x)),
                    ],
                  );
                },
              ),
              //INPUT
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CustomTextFormField(
                      controller: _nameController,
                      labelText: 'Name',
                      validator: validator,
                    ),
                    SizedBox(height: rh(space2x)),
                    CustomTextFormField(
                      controller: _websiteController,
                      labelText: 'Website URL',
                      validator: validator,
                      textInputType: TextInputType.url,
                    ),
                    SizedBox(height: rh(space2x)),
                    CustomTextFormField(
                      controller: _twitterController,
                      labelText: 'Twitter URL',
                      validator: validator,
                      textInputType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                    ),
                    SizedBox(height: rh(space2x)),
                  ],
                ),
              ),

              SizedBox(height: rh(space3x)),

              //ACTION BUTTONS
              Buttons.expanded(
                context: context,
                text: 'Enter the world of NFT',
                onPressed: _submit,
              ),
              SizedBox(height: rh(space3x)),

              Center(
                child: Buttons.text(
                  context: context,
                  text: 'Skip For Now',
                  onPressed: _skipForNow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
