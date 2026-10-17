import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';

import 'constant.dart';

class Permissions {
  static Future<bool> cameraFilesAndLocationPermissionsGranted() async {
    if (!getBoolAsync(PERMISSION_STATUS)) {
      Map<Permission, PermissionStatus> cameraPermissionStatus = {};

      if (isIOS) {
        // Request camera + while using
        cameraPermissionStatus[Permission.camera] = await Permission.camera.request();
        cameraPermissionStatus[Permission.locationWhenInUse] = await Permission.locationWhenInUse.request();

        // OPTIONAL: If you really need Always, request it after whenInUse is granted
        // if (cameraPermissionStatus[Permission.locationWhenInUse] == PermissionStatus.granted) {
        //   cameraPermissionStatus[Permission.locationAlways] = await Permission.locationAlways.request();
        // }
      } else {
        // Android
        cameraPermissionStatus[Permission.camera] = await Permission.camera.request();
        cameraPermissionStatus[Permission.location] = await Permission.location.request();
      }

      bool allGranted = cameraPermissionStatus.values.every((status) => status == PermissionStatus.granted);

      if (!allGranted) {
        // Only open settings if any is permanently denied
        if (cameraPermissionStatus.values.contains(PermissionStatus.permanentlyDenied)) {
          openAppSettings();
        }
      }

      return allGranted;
    }
    return true;
  }

}