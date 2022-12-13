import 'dart:io';

import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';

String lastModfiedKey = "FSLastModifiedScript";
String hitCacheFolder = "/flagship/cache/hits/";
String fileName = "bucketing.json";

class StorageManagment {
  static void storeJson(String jsonToStore, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    Directory bucketingDirectory =
        await Directory.fromUri(Uri.file(directory.path + hitCacheFolder))
            .create(recursive: true)
            .catchError((error) {
      Flagship.logger(Level.DEBUG,
          "Enable to create the directory to save the cache hits file ");
    });
    // We got the path to save the json file
    File jsonFile = File(bucketingDirectory.path + fileName);
    jsonFile.writeAsString(jsonToStore);
  }

  String readJson() {
    return "";
  }
}
