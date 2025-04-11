import 'package:app_version_update_lite/app_version_update_lite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_camera_flutter/map_camera_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';
import 'camera_screen.dart';

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  SplashScreen({required this.cameras});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  NavigatorState? _navigator;
  final playStoreId = 'com.mas.gps_map_camera.mas_gps_map_camera';

  @override
  void initState() {
    super.initState();
    checkUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
  }

  @override
  void dispose() {
    // // Don't pop if the widget is already disposed
    // if (mounted) {
    //   _navigator?.pop();
    // }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Image.asset(height: 200, AppImages.logo, fit: BoxFit.cover),
      ),
    );
  }


  checkUpdate() async {
    await AppVersionUpdate.checkForUpdates(
      playStoreId: playStoreId,
      country: 'in',
    ).then((result) async {
      if (result.canUpdate!) {
        showUpdateDialog(context);
      } else {
        checkallpermissiongrant();
      }
    });
  }

  void showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing the dialog
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(5, 10, 5, 0),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            title: Text(
              "Update Available",
              textAlign: TextAlign.center,
            ),
            content: Container(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Please Update to Continue.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  )
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text("Update"),
                onPressed: () {
                  if (Platform.isAndroid) {
                    launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=$playStoreId"));
                  }
                }, // Call the _submit method here
               // Use your AppColors here
              ),
            ],
          ),
        );
      },
    );
  }


  Future<bool> checkAllPermissionsGranted() async {
    // Check if all required permissions are granted
    PermissionStatus cameraStatus = await Permission.camera.status;
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    PermissionStatus locationStatus = await Permission.location.status;
    PermissionStatus manageExternalStorageStatus = await Permission.manageExternalStorage.status;

    // If any of the permissions is not granted, return false
    if (cameraStatus.isDenied || microphoneStatus.isDenied || locationStatus.isDenied || manageExternalStorageStatus.isDenied) {
      return false;
    }

    // If any permission is permanently denied (on Android), return false
    if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied || locationStatus.isPermanentlyDenied || manageExternalStorageStatus.isPermanentlyDenied) {
      return false;
    }

    // All permissions granted
    return true;
  }

  Future<void> checkPermissionsAndRedirect(BuildContext context) async {
    // Request all permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
     // Permission.storage,
    ].request();

    // Check if any permission is denied and show the corresponding dialog
    if (!statuses[Permission.camera]!.isGranted) {
      _showPermissionDialog('Camera', Permission.camera);
    } else if (!statuses[Permission.microphone]!.isGranted) {
      _showPermissionDialog('Microphone', Permission.microphone);
    } else if (!statuses[Permission.location]!.isGranted) {
      _showPermissionDialog('Location', Permission.location);
    }  else {
      navigateToNextScreen();

    }
  }

  void _showPermissionDialog(String permissionName, Permission permission) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$permissionName Permission Required'),
          content: Text('This app needs access to your $permissionName.'),
          actions: [
            TextButton(
              onPressed: () async {
                print('before permission status ${permission.status}');

                PermissionStatus status = await permission.request();
                print('after permission status $status');

                if (status.isGranted) {
                  print("permission granted");
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      checkPermissionsAndRedirect(context);
                    }
                  });
                } else if (status.isDenied) {
                  print("permission denied");
                  Navigator.of(context).pop();
                  // checkPermissionsAndRedirect(context);
                } else if (status.isPermanentlyDenied) {
                  print("Permission permanently denied. Navigating to settings.");
                  openAppSettings().then((value) {
                    WidgetsBinding.instance.addPostFrameCallback((value) {
                      // Navigator.of(context).pop();

                      if (mounted) {

                        checkPermissionsAndRedirect(context);
                      }
                    });
                  });
                }
              },
              child: Text('Grant Permission'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Optionally, handle cancel action
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkallpermissiongrant() async {
    bool checkPermissionGrant = await checkAllPermissionsGranted();

    if (!checkPermissionGrant) {

      checkPermissionsAndRedirect(context);
    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            cameras: widget.cameras,
          ),
        ),
      );
    }
  }

  void navigateToNextScreen() {
    // Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            cameras: widget.cameras,
          ),
        ),
      );
    });
  }
}
