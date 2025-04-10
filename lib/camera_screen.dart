import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:map_camera_flutter/map_camera_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraScreen({required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  Future<void>? _cameraInitializeFuture;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;
  bool _isSwitchingCamera = false;

  bool _isRecording = false;
  String btnText = "Start Recording";
  String? _videoPath;
  String? _finalVideoPath;
  String? _locationText;
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((value) {
      if (mounted) _initializeCamera(_selectedCameraIndex);
    });
  }

  /// Initializes the camera
  Future<void> _initializeCamera(int cameraIndex) async {
    print("Initializing camera index: $cameraIndex");

    if (!mounted) {
      print("Widget is not mounted. Returning.");
      return;
    }

    try {
      if (cameraIndex >= widget.cameras.length) {
        print("Invalid camera index: $cameraIndex");
        return;
      }

      // Dispose of old camera controller
      await _cameraController?.dispose();
      _cameraController = null;

      // Start new camera initialization
      final CameraController controller = CameraController(
        widget.cameras[cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraInitializeFuture = controller.initialize();
      await _cameraInitializeFuture; // Wait until initialized

      if (!mounted) return;

      SchedulerBinding.instance.addPostFrameCallback((value) {
        if (mounted) {
          setState(() {
            print("Camera initialized at index: $cameraIndex");
            _cameraController = controller;
          });
        }
      });
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  /// Toggles the flashlight
  void _toggleFlashlight() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isSwitchingCamera) return;

    try {
      await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.torch);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print("Error toggling flashlight: $e");
    }
  }

  /// Switches between front and back cameras
  void _switchCamera() async {
    if (_isSwitchingCamera || widget.cameras.length < 2) return;

    setState(() {
      _isSwitchingCamera = true;
    });

    int newIndex = _selectedCameraIndex == 0 ? 1 : 0;
    print("Switching to camera index: $newIndex");

    await _initializeCamera(newIndex);

    setState(() {
      _selectedCameraIndex = newIndex;
      _isSwitchingCamera = false;
    });
  }

  Future<void> _startRecording() async {
    final loc = await Geolocator.getCurrentPosition();
    _locationText = 'Lat: ${loc.latitude}, Lng: ${loc.longitude}';

    final dir = await getTemporaryDirectory();
    _videoPath = p.join(dir.path, 'recorded.mp4');

    await _cameraController?.startVideoRecording();
   // setState(() => _isRecording = true);
    setState(() {
      _isRecording = true;
      btnText = "Stop Recoding";
    });
  }

  Future<void> _stopRecording() async {
    final file = await _cameraController?.stopVideoRecording();
   // setState(() => _isRecording = false);
    setState(() {
      _isRecording = false;
      btnText = "Start Recoding";
    });
    _videoPath = file?.path;
    _saveVideoToGallery(file!.path,_locationText!);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _cameraInitializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                MapCameraLocation(
                  camera: widget.cameras[_selectedCameraIndex],
                  onImageCaptured: (ImageAndLocationData data) async {
                    print('Captured image path: ${data.imagePath}');
                    print('Latitude: ${data.latitude}');
                    print('Longitude: ${data.longitude}');
                    _saveImageToGallery(data.imagePath!);
                  },
                  onGalleryClick: (){
                    _openGallery();
                  },
                  onVideoClick: (){
                    _isRecording ? _stopRecording() : _startRecording();
                  },
                  btnText: btnText,
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
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  /// Opens the gallery
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

  /// Saves captured image to the gallery
  Future<void> _saveImageToGallery(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/saved_image.jpg';

      final newFile = File(filePath)..writeAsBytesSync(Uint8List.fromList(img.encodeJpg(image)));

      if (Platform.isAndroid || Platform.isIOS) {
        final result = await MethodChannel('com.mas.gps_map_camera.mas_gps_map_camera/gallery').invokeMethod('saveToGallery', {'path': newFile.path});
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

  Future<void> _saveVideoToGallery(String videoPath, String text) async {
    try {
      final inputFile = File(videoPath);

      if (!await inputFile.exists()) {
        throw Exception("Video file does not exist: $videoPath");
      }

      final directory = await getExternalStorageDirectory();
      final now = DateTime.now();
      final safeTimestamp = now.toIso8601String().replaceAll(RegExp(r'[:.]'), '_');
      final filePath = '${directory!.path}/${safeTimestamp}_video.mp4';
      final newFile = await inputFile.copy(filePath);

      print("Output video path: ${newFile.path}");

      if (Platform.isAndroid || Platform.isIOS) {
        // Log the text to verify its correctness
        print("Text to be used in overlay: '$text'");

        final escapedText = text
            .replaceAll("'", "\\\\'")
            .replaceAll(":", "\\:");

        final command =
            "-y -i $videoPath -vf \"drawtext=fontfile=/system/fonts/DroidSans.ttf:text='${escapedText}':fontcolor=red:fontsize=24:x=10:y=10\" -c:v libx264 -c:a aac -f mp4 ${newFile.path}";

        // Execute FFmpeg command to add text overlay
        final session = await FFmpegKit.execute(command);

        final returnCode = await session.getReturnCode();
        if (returnCode!.isValueSuccess()) {
          print('Video processed successfully with overlay.');
        } else {
          // Collect detailed logs from FFmpeg
          final outputLog = await session.getAllLogs();
          print('FFmpeg failed:');
          for (var log in outputLog) {
            print(log.getMessage());
          }
        }

        setState(() {});
        final result = await MethodChannel('com.mas.gps_map_camera.mas_gps_map_camera/gallery')
            .invokeMethod('saveVideoToGallery', {'path': newFile.path});
        print('Video saved to gallery: $result');
      }
    } catch (e) {
      print('Error saving video: $e');
    }
  }

}
