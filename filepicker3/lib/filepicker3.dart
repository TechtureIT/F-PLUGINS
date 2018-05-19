import 'dart:async';

import 'package:flutter/services.dart';

class Filepicker3 {
  static const MethodChannel _channel =
      const MethodChannel('filepicker3');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

//  static Future<String> get selectFile async {
//    print("PLUGIN : SELECT FLE CALLED");
//    String fileName = await _channel.invokeMethod("selectFile");
//    print("PLUGIN : " + fileName.toString());
//    return fileName;
//  }


  static Future<String> selectFile() async {
    print("PLUGIN : SELECT FLE CALLED");
    String fileName = await _channel.invokeMethod("selectFile");
    print("PLUGIN : " + fileName.toString());
    return fileName;
  }
}

