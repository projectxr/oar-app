import 'package:flutter/material.dart';

class AppConstants {
  double height = 0;
  double width = 0;
  double aspectRatio = 0;
  double _heightCalculator(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    return (MediaQuery.of(context).size.height);
  }

  double _widthCalculator(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    return (MediaQuery.of(context).size.width);
  }

  _calculateAspectRatio(double width, double height) => height / width;

  static final AppConstants _instance = AppConstants._internal();
  factory AppConstants() {
    return _instance;
  }
  AppConstants._internal();

  void calculateSize(BuildContext context) {
    aspectRatio = _calculateAspectRatio(_widthCalculator(context), _heightCalculator(context));
  }
}

/////////////Commons\\\\\\\\\\\\\\
const THEME_COLOR = Colors.teal;
double INVERSE_ASPECT_RATIO = 1 / AppConstants().aspectRatio;
const double MARGIN_MULTIPLIER = 0.1;
const double V_LARGE_PAD = 100;
const double LARGE_PAD = 40;
const double MEDIUM_PAD = 20;
const double SMALL_PAD = 10;
const double V_SMALL_PAD = 4;
const double VV_SMALL_PAD = 2;
const double VVV_SMALL_PAD = 1.5;
const double RADIUS = 10;
const double LIST_RADIUS = 50;
const double RADIUS_SMALL = 10;
const double FORM_FIELD_RADIUS = 32;
const double DEFAULT_FONT_SIZE = 32;
const double REGULAR_FONT_SIZE = 20;
const double V_SMALL_FONT_SIZE = 12;
const double SMALL_FONT_SIZE = 15;
const double TEXT_FIELD_ELEVATION = 8;
const double TEXT_FIELD_BORDER_RADIUS = 5;
const Color TEXT_FIELD_ICON_COLOR = Colors.black;
const Color TEXT_FIELD_CURSOR_COLOR = Colors.black;
const Color OVERLAY_BG_COLOR = Colors.black38;
const FontWeight BOLD_WEIGHT = FontWeight.w700;
const FontWeight NORMAL_WEIGHT = FontWeight.w500;
const Color TEXT_COLOR_BRIGHT = Color(0XFFF0DBA5);
const Color TEXT_COLOR_DARK = Color(0XFF5D1815);
double SCREEN_RATIO = AppConstants().height / AppConstants().width;
const double BG_MUSIC_VOLUME_LEVEL = 0.7;
const Color NON_IMAGE_BG_COLOR = Color(0XFFFFF7CC);
const APP_TITLE = 'Flutter Scaffold';
const SECURE_STORAGE_TOKEN_KEY = 'token';
const EdgeInsets FORM_PADDING = EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0);
