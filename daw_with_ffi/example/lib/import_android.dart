import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.request().isGranted) {
      debugPrint("Storage permission: ACCEPTED");
    } else {
      debugPrint("Storage permission: REJECTED");
    }

    if (await Permission.manageExternalStorage.request().isGranted) {
      debugPrint("Manage external storage permission: ACCEPTED");
    } else {
      debugPrint("Manage external storage permission: REJECTED");
    }
  }
}
