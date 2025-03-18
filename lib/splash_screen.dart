import 'package:flutter/material.dart';
import 'package:map_camera_flutter/map_camera_flutter.dart';
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
    Future.delayed(Duration(milliseconds: 2000), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen(cameras: widget.cameras,)),);
    });
//request permission
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
}
