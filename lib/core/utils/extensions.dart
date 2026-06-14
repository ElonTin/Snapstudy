import 'package:flutter/material.dart';
import 'package:snapstudy/core/widgets/app_snackbar.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  bool get isDark => theme.brightness == Brightness.dark;

  void showSnack(String message, {bool isError = false}) {
    AppSnackBar.show(
      this,
      message: message,
      type: isError ? AppSnackType.error : AppSnackType.info,
    );
  }
}

extension StringX on String {
  bool get isNullOrEmpty => trim().isEmpty;
}
