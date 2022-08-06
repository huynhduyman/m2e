import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../custom_widgets.dart';

Future<DateTime> openDatePicker({
  required BuildContext context,
  required DateTime initalDate,
  required DateTime startDate,
  required DateTime lastDate,
}) async {
  //Assinging intial date
  DateTime selectedDate = initalDate;

  //Check Platform and display appropriate widget
  if (Platform.isIOS) {
    await openBottomSheet(
      context: context,
      child: CupertinoDatePicker(
        initialDateTime: selectedDate,
        mode: CupertinoDatePickerMode.date,
        minimumDate: startDate,
        maximumDate: lastDate,
        onDateTimeChanged: (DateTime newDateTime) {
          selectedDate = newDateTime;
        },
      ),
    );
  } else {
    selectedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: startDate,
          lastDate: lastDate,
        ) ??
        selectedDate;
  }

  return selectedDate;
}
