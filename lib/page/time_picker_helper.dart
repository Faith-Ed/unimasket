import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class TimePickerHelper {
  // This function shows the Omni DateTime Picker and returns the selected date-time as a string.
  static Future<String?> pickServiceTime(BuildContext context) async {
    print("Picking date and time..."); // Debug print
    // Show the Omni DateTime Picker with both date and time selection
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1600),
      lastDate: DateTime.now().add(Duration(days: 3652)),
      is24HourMode: true,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: BorderRadius.all(Radius.circular(16)),
      constraints: BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      transitionDuration: Duration(milliseconds: 200),
      barrierDismissible: true,
    );

    // If a date/time is selected, format it as yyyy-mm-dd hh:mm
    if (dateTime != null) {
      return "${dateTime.toLocal().year}-${dateTime.toLocal().month}-${dateTime.toLocal().day} ${dateTime.toLocal().hour}:${dateTime.toLocal().minute}";
    }

    return null; // Return null if no date is selected
  }
}
