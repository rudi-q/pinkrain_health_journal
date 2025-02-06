import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

ColorFilter defaultColorFilter([Color? color]) {
  return ColorFilter.mode(
    color ?? Colors.black,
    BlendMode.srcIn,
  );
}

SvgPicture appVectorImage({
  required String fileName,
  double? size,
  Color? color,
  bool? useColorFilter
}){
  return SvgPicture.asset(
    'assets/icons/$fileName.svg',
    colorFilter: useColorFilter == false ? null : defaultColorFilter(color),
    width: size ?? 20,
    height: size ?? 20,
  );
}

dynamic appImage(String fileName, {double? size, Color? color, bool? useColorFilter}) {
  return Image.asset(
    'assets/icons/$fileName.png',
    width: size,
    height: size,
    color: useColorFilter == false ? null : color,
    colorBlendMode: useColorFilter == false ? null : BlendMode.srcIn,
  );
}



