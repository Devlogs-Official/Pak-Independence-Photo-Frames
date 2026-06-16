import 'package:flutter/material.dart';

class AppSnackbars {
  AppSnackbars._();

  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
