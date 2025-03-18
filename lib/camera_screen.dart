import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:map_camera_flutter/map_camera_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraScreen({required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera(_selectedCameraIndex);
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    try {
      _cameraController = CameraController(
        widget.cameras[cameraIndex], // Use new camera
        ResolutionPreset.high,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _toggleFlashlight() async {
    if (_cameraController?.value.isInitialized ?? false) {
      try {
        await _cameraController!
            .setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.torch);
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      } catch (e) {
        print("Error toggling flashlight: $e");
      }
    }
  }

  void _switchCamera() async {
    if (widget.cameras.length < 2) {
      print("No front camera available!");
      return;
    }

    int newIndex = _selectedCameraIndex == 0 ? 1 : 0;

    // Dispose old controller before switching
    await _cameraController?.dispose();

    setState(() {
      _selectedCameraIndex = newIndex;
      _isCameraInitialized = false; // Temporarily hide UI
      _cameraController = null; // Ensure proper cleanup
    });

    // Reinitialize with new camera
    await _initializeCamera(newIndex);

    setState(() {
      _isCameraInitialized = true; // Show UI again
    });
  }


  @override
  void dispose() {
    _cameraController?.dispose(); // Safe disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:

      Stack(
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)

            MapCameraLocation(
              camera: widget.cameras[_selectedCameraIndex],
              onGalleryClick: _openGallery,
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

          // Switch Camera Button
          Positioned(
            top: 100,
            right: 20,
            child: IconButton(
              icon: Icon(
                Icons.switch_camera,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _switchCamera,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGallery() async {
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
  }

  Future<void> _saveImageToGallery(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

      // Get the directory where the image will be saved
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/saved_image.jpg';

      // Write the image to the new file path
      final newFile = File(filePath)
        ..writeAsBytesSync(Uint8List.fromList(img.encodeJpg(image)));

      // Save to the gallery
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await MethodChannel(
                'com.mas.gps_map_camera.mas_gps_map_camera/gallery')
            .invokeMethod('saveToGallery', {'path': newFile.path});
        print('Image saved to gallery: $result');
        Fluttertoast.showToast(
          msg: "Image saved to gallery",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print('Error saving image: $e');
    }
  }
}
