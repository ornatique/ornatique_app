import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Color_Constant {

  static const Color primary = Color(0xFF0A3D62);  // Dark Blue
  static const Color secondary = Color(0xFF01A3A4); // Teal
  static const Color accent = Color(0xFFF79F1F);    // Orange
  static const Color background = Color(0xFFF5F5F5); // Light Grey
  static const Color textColor = Color(0xFF333333); // Dark Text

  // Newly Added Colors
  static const Color black = Colors.black;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color purple = Colors.purple;
  static const Color blue = Colors.blue;
  static const Color amber = Colors.amber;
  static const Color blueAccent = Colors.blueAccent;
  static const Color pink = Colors.pink;
  static const Color grey = Colors.grey;


  // Using a getter for non-constant colors
  static Color get lightBlue => Colors.blue[100]!;
  static Color get lightBlue50 => Colors.blue[50]!;
  static Color get Blue300 => Colors.blue[300]!;
  static Color get greyshade300 => Colors.grey[300]!;
  static Color get greyshade50 => Colors.grey[50]!;
  static Color get amber700 => Colors.amber[700]!;
}

class AppColorHelper {
  static Future<Color> getAppBarColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? hexColor = prefs.getString("app_bar_color");
    if (hexColor != null && hexColor.isNotEmpty) {
      return getColorFromHex(hexColor);
    }
    return Colors.white; // default
  }

  static Future<Color> getBackgroundColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? hexColor = prefs.getString("back_ground_color");
    if (hexColor != null && hexColor.isNotEmpty) {
      return getColorFromHex(hexColor);
    }
    return Colors.white; // default
  }

  static Color getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // 100% opacity add
    }
    return Color(int.parse("0x$hexColor"));
  }

}


class ColorHelper {
  static Future<Color> getBottomBarColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? hexColor = prefs.getString("app_bottom_color");
    print("Bottom Color " + hexColor.toString());
    if (hexColor != null && hexColor.isNotEmpty) {
      return _getColorFromHex(hexColor);
    }
    return Colors.white; // default color
  }

  static Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // opacity add
    }
    return Color(int.parse("0x$hexColor"));
  }
}