import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:map_camera_flutter/map_camera_flutter.dart';
import 'package:image/image.dart' as img;
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  CameraScreen({required this.camera});
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: MapCameraLocation(
          camera: widget.camera,
          onImageCaptured: (ImageAndLocationData data) async {
            print('Captured image path: ${data.imagePath}');
            print('Latitude: ${data.latitude}');
            print('Longitude: ${data.longitude}');
            print('Location name: ${data.locationName}');
            print('Sublocation: ${data.subLocation}');
            _saveImageToGallery(data.imagePath!);

          },
        ));
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
