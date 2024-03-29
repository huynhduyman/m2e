import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_picker_windows/image_picker_windows.dart';
import'dart:io' show Platform;

class ImagePickerService {

// PICKER
  static Future<XFile?> pickImage() async {
    final ImagePicker _picker = ImagePicker();

    // final ImagePickerPlatform _picker = ImagePickerPlatform.instance;
    // if(Platform.isWindows){
    //   final ImagePickerPlatform _picker = ImagePickerPlatform.instance;
    //   debugPrint('isWindows');
    // } else {
    //   final ImagePicker _picker = ImagePicker();
    // }

    try {
      // Pick an image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      debugPrint('File Selected: $image');

      //Nothing picked
      if (image == null) {
        Fluttertoast.showToast(
          msg: 'No File Selected',
        );
        return null;
      } else {
        //Return Path
        return image;
      }
    } catch (e) {
      debugPrint('Error at image picker: $e');

      return null;
    }
  }

}
