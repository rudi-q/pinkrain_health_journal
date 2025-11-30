import 'package:flutter/material.dart';
import 'colors.dart';

class AppTokens {
  /// TEXT COLORS for PinkRain
  static const textPrimary = AppColors.black100;
  static const textSecondary = AppColors.black40;
  static const textPlaceholder = AppColors.black40;
  static const textDisabled = AppColors.black40;

  static const textInvert = AppColors.white100;

  // FONT WEIGHTS
  static const fontWeightNormal = FontWeight.normal;
  static const fontWeightBold = FontWeight.bold;
  static const fontWeightW400 = FontWeight.w400;
  static const fontWeightW500 = FontWeight.w500;
  static const fontWeightW600 = FontWeight.w600;

  // DEFAULT TEXT STYLES
  static const TextStyle textStyleDefault = TextStyle(
    color: textPrimary,
    fontWeight: fontWeightBold,
    fontFamily: 'Outfit',
  );
  
  static const TextStyle textStyleSmall = TextStyle(
    color: textPrimary,
    fontWeight: fontWeightBold,
    fontSize: 14,
    fontFamily: 'Outfit',
  );
  
  static const TextStyle textStyleMedium = TextStyle(
    color: textPrimary,
    fontWeight: fontWeightBold,
    fontSize: 16,
    fontFamily: 'Outfit',
  );
  
  static const TextStyle textStyleLarge = TextStyle(
    color: textPrimary,
    fontWeight: fontWeightBold,
    fontSize: 18,
    fontFamily: 'Outfit',
  );
  
  static const TextStyle textStyleXLarge = TextStyle(
    color: textPrimary,
    fontWeight: fontWeightBold,
    fontSize: 24,
    fontFamily: 'Outfit',
  );

  // SECONDARY TEXT STYLES
  static const TextStyle textStyleSecondary = TextStyle(
    color: textSecondary,
    fontWeight: fontWeightBold,
    fontFamily: 'Outfit',
  );

  static const TextStyle textStyleSecondarySmall = TextStyle(
    color: textSecondary,
    fontWeight: fontWeightBold,
    fontSize: 12,
    fontFamily: 'Outfit',
  );

  static const TextStyle textStyleSecondaryMedium = TextStyle(
    color: textSecondary,
    fontWeight: fontWeightBold,
    fontSize: 14,
    fontFamily: 'Outfit',
  );


  // BACKGROUND
  static const bgPrimary = AppColors.white100;
  static const bgMuted = AppColors.black5;
  static const bgElevated = AppColors.white100;
  static final bgCard = AppColors.pink40;

  // BORDER
  static const borderLight = AppColors.black10;
  static const borderStrong = AppColors.black40;

  // BUTTON PRIMARY
  static const buttonPrimaryBg = AppColors.pink100;
  static const buttonElevatedBg = AppColors.pink40;
  static const buttonPrimaryText = AppColors.black100;

  // BUTTON SECONDARY
  static const buttonSecondaryBg = AppColors.black5;
  static const buttonSecondaryText = AppColors.black100;

  // ICONS
  static const iconPrimary = AppColors.black100;
  static const iconBold = AppColors.pink100;
  static const iconMuted = AppColors.black40;

  // FEEDBACK STATES
  static const stateSuccess = AppColors.strongGreen;
  static const stateError = AppColors.strongRed;
  static const stateInfo = AppColors.strongBlue;

  // CURSOR
  static const cursor = AppColors.pink100;
}