import 'package:flutter/material.dart';
import 'package:map_camera_flutter/map_camera_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((value) {
      checkPermissionsAndRedirect(context);
    });
  }

  @override
  void dispose() {
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

  Future<void> checkPermissionsAndRedirect(BuildContext context) async {
    // Request all permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.manageExternalStorage,
    ].request();

    // Check if any permission is denied and show the corresponding dialog
    if (!statuses[Permission.camera]!.isGranted) {
      _showPermissionDialog(context, 'Camera', Permission.camera);
    } else if (!statuses[Permission.microphone]!.isGranted) {
      _showPermissionDialog(context, 'Microphone', Permission.microphone);
    } else if (!statuses[Permission.location]!.isGranted) {
      _showPermissionDialog(context, 'Location', Permission.location);
    } else if (!statuses[Permission.manageExternalStorage]!.isGranted) {
      _showPermissionDialog(context, 'External Storage', Permission.manageExternalStorage);
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

  void _showPermissionDialog(BuildContext context, String permissionName, Permission permission) {
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
                  checkPermissionsAndRedirect(context);
                } else if (status.isDenied) {
                  print("permission denied");
                } else if (status.isPermanentlyDenied) {
                  print("Permission permanently denied. Navigating to settings.");
                  openAppSettings();
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
}
