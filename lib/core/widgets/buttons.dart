import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

class Button {
  static TextButton primary({
    required VoidCallback onPressed,
    required String text,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    String fontFamily = 'Outfit',
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    double borderRadius = 12,
    Color textColor = AppTokens.textPrimary,
    Color backgroundColor = AppColors.pink100,
    Color borderColor = AppTokens.borderLight
  }) {
    return _baseButton(
      onPressed: onPressed,
      text: text,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderColor: Colors.transparent,
      borderWidth: 0,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  static TextButton secondary({
    required VoidCallback onPressed,
    required String text,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    String fontFamily = 'Outfit',
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    double borderRadius = 12,
    Color textColor = AppTokens.textPrimary,
    Color backgroundColor = AppTokens.buttonSecondaryBg,
    Color borderColor = AppTokens.borderLight,
    double borderWidth = 1.5,
  }) {
    return _baseButton(
      onPressed: onPressed,
      text: text,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  static TextButton _baseButton({
    required VoidCallback onPressed,
    required String text,
    required Color textColor,
    required Color backgroundColor,
    required Color borderColor,
    required double borderWidth,
    required double fontSize,
    required FontWeight fontWeight,
    required String fontFamily,
    required EdgeInsets padding,
    required double borderRadius,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          color: textColor,
        ),
      ),
    );
  }
}
