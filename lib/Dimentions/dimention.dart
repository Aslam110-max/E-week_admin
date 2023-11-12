import 'package:flutter/cupertino.dart';

class Dimensions {
  static double? screenHeight =
      MediaQueryData.fromView(WidgetsBinding.instance.window).size.height;
  static double? screenWidth =
      MediaQueryData.fromView(WidgetsBinding.instance.window).size.width;
  static double height10 = screenHeight! / 60;
  static double height100 = screenHeight! / 6;
  static double width10 = screenWidth! / 35;
  static double width150 = screenWidth! / 2.0;
}
