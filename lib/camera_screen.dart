import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:map_camera_flutter/map_camera_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  CameraScreen({required this.camera});
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(widget.camera, ResolutionPreset.high);
    await _cameraController.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _toggleFlashlight() async {
    if (_isCameraInitialized) {
      try {
        await _cameraController.setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.torch);
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      } catch (e) {
        print("Error toggling flashlight: $e");
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isCameraInitialized)
            MapCameraLocation(
              camera: widget.camera,
              onGalleryClick: () async {
                if (Platform.isAndroid) {
                  const intent = AndroidIntent(
                    action: 'android.intent.action.VIEW',
                    type: 'image/*',
                    flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                  );
                  await intent.launch();
                } else if (Platform.isIOS) {
                  final Uri uri = Uri.parse("photos-redirect://");
                  if (!await launchUrl(uri)) {
                    throw Exception("Could not open gallery");
                  }
                } else {
                  throw UnsupportedError("This platform is not supported");
                }
              },
              onImageCaptured: (ImageAndLocationData data) async {
                print('Captured image path: ${data.imagePath}');
                print('Latitude: ${data.latitude}');
                print('Longitude: ${data.longitude}');
                print('Location name: ${data.locationName}');
                print('Sublocation: ${data.subLocation}');
                _saveImageToGallery(data.imagePath!);
              },
            ),

          // Flashlight Toggle Button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _toggleFlashlight,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _saveImageToGallery(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

      // Get the directory where the image will be saved
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/saved_image.jpg';

      // Write the image to the new file path
      final newFile = File(filePath)..writeAsBytesSync(Uint8List.fromList(img.encodeJpg(image)));

      // Save to the gallery (you may need platform-specific code here)
      if (Platform.isAndroid) {
        // On Android, we need to use a platform channel or use MediaStore to save to the gallery
        final result = await MethodChannel('com.mas.gps_map_camera.mas_gps_map_camera/gallery')
            .invokeMethod('saveToGallery', {'path': newFile.path});
        print('Image saved to gallery: $result');
        Fluttertoast.showToast(
            msg: "Image saved to gallery",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
        );
      } else if (Platform.isIOS) {
        // On iOS, save the image to the gallery
        final result = await MethodChannel('com.mas.gps_map_camera.mas_gps_map_camera/gallery')
            .invokeMethod('saveToGallery', {'path': newFile.path});
        print('Image saved to gallery: $result');
        Fluttertoast.showToast(
            msg: "Image saved to gallery",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
        );
      }
    } catch (e) {
      print('Error saving image: $e');
    }
  }
}
