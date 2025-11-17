import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/foundation.dart';

Future<File?> downloadMp3(String url) async {
  Dio dio = Dio();
  Directory tempDir = await getTemporaryDirectory();
  String fileName = url.split('/').last; 
  String savePath = '${tempDir.path}/$fileName';

  // Check if the file already exists
  File file = File(savePath);
  if (await file.exists()) {
    // File already exists, no need to download again
    return file;
  }

  try {
    EasyLoading.show(
      status: 'Downloading...',
    );
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          if (kDebugMode) {
            print('${(received / total * 100).toStringAsFixed(0)}%');
          }
        }
      },
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error downloading file: $e');
    }
    EasyLoading.showError('Failed to download file');
    return null; // Return null to indicate failure
  } finally {
    EasyLoading.dismiss();
  }

  return File(savePath);
}
