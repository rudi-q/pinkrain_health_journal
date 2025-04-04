import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../util/helpers.dart';


ColorFilter defaultColorFilter([Color? color]) {
  return ColorFilter.mode(
    color ?? Colors.black,
    BlendMode.srcIn,
  );
}

Future<SvgPicture> appSvgDynamicImage({
    required String fileName,
    double? size,
    Color? color,
    bool? useColorFilter,
    }) async {
  try {
    String svgString = await rootBundle.loadString('assets/icons/$fileName.svg');
    if(color != null && color != Colors.white){
      svgString = svgString.replaceAll('#8BE8CB', colorToHex(color));
      svgString = svgString.replaceAll('#05D1A1', colorToHex(darkenColor(color)));
    }
    return SvgPicture.string(
      svgString,
      width: size ?? 20,
      height: size ?? 20,
    );
  } catch (e) {
    "Error occurred while rendered updated svg: $e".log();
    return appVectorImage(fileName: fileName, size: size, color: color, useColorFilter: useColorFilter);
  }
}

SvgPicture appVectorImage({
  required String fileName,
  double? size,
  Color? color,
  bool? useColorFilter
}){
  try{
    return SvgPicture.asset(
      'assets/icons/$fileName.svg',
      width: size ?? 20,
      height: size ?? 20,
      colorFilter: useColorFilter == false
          ? null
          : defaultColorFilter(color),
    );
  } catch (e) {
    "Error occurred while rendered vector image: $e".log();
    return appVectorImage(fileName: 'medicine', size: size, color: color, useColorFilter: useColorFilter);
  }
}

Image appImage(String fileName, {double? size, Color? color, bool? useColorFilter}) {
  return Image.asset(
    'assets/icons/$fileName.png',
    width: size,
    height: size,
    color: useColorFilter == false ? null : color,
    colorBlendMode: useColorFilter == false ? null : BlendMode.srcIn,
  );
}

String colorToHex(Color color) {
  // Get the RGB value (ignore alpha by masking with 0xFFFFFF)
  String hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
  return '#$hex'.toUpperCase();
}

Color darkenColor(Color color, [double factor = 0.8]) {
  // Clamp the factor between 0 and 1 (0 = black, 1 = no change)
  factor = factor.clamp(0.0, 1.0);

  // Extract RGB components
  int red = color.red;
  int green = color.green;
  int blue = color.blue;

  // Darken each component by multiplying with the factor
  red = (red * factor).round().clamp(0, 255);
  green = (green * factor).round().clamp(0, 255);
  blue = (blue * factor).round().clamp(0, 255);

  // Return the new color, preserving the original alpha
  return Color.fromARGB(color.alpha, red, green, blue);
}






