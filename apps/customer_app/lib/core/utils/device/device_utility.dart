import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceUtils {
  DeviceUtils._();

  static void hideKeyboard(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static Future<void> setStatusBarColor(Color color) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double pixelRatio(BuildContext context) =>
      MediaQuery.devicePixelRatioOf(context);

  static double statusBarHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  static double keyboardHeight(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom;

  static bool isKeyboardVisible(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0;

  static bool get isPhysicalDevice =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static void vibrate() => HapticFeedback.mediumImpact();

  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) {
    return SystemChrome.setPreferredOrientations(orientations);
  }

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  static bool get isIOS => Platform.isIOS;

  static bool get isAndroid => Platform.isAndroid;

  static Future<void> launchWebsiteUrl(String address) async {
    final uri = Uri.parse(address);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint('Could not launch $uri');
      }
    }
  }
}

typedef TDeviceUtils = DeviceUtils;
