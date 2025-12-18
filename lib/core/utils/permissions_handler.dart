import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> handlePermission(Permission permission, String name) async {
  var status = await permission.request();

  if (status.isGranted) {
    Fluttertoast.showToast(msg: '$name permission granted');
  } else if (status.isPermanentlyDenied) {
    Fluttertoast.showToast(
      msg: '$name permission permanently denied. Enable it in settings.',
    );
    openAppSettings();
  } else if (status.isRestricted) {
    Fluttertoast.showToast(msg: '$name permission restricted by system.');
  } else if (status.isLimited) {
    Fluttertoast.showToast(msg: '$name permission limited access granted.');
  } else {
    Fluttertoast.showToast(msg: '$name permission denied');
  }
}
