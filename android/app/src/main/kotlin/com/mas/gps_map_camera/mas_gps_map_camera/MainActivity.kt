package com.mas.gps_map_camera.mas_gps_map_camera

import android.content.ContentValues
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mas.gps_map_camera.mas_gps_map_camera/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize the MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveToGallery") {
                val path = call.argument<String>("path")
                if (path != null) {
                    saveImageToGallery(path, result)
                } else {
                    result.error("INVALID_ARGUMENT", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(path: String, result: MethodChannel.Result) {
        try {
            val imageFile = File(path)
            if (!imageFile.exists()) {
                result.error("ERROR", "Image file does not exist", null)
                return
            }

            val contentValues = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, imageFile.name)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/MyApp")
            }

            val contentResolver = contentResolver
            val imageUri: Uri? = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)

            if (imageUri != null) {
                val inputStream: InputStream = FileInputStream(imageFile)
                val outputStream: OutputStream? = contentResolver.openOutputStream(imageUri)
                outputStream?.let {
                    inputStream.copyTo(it)
                    it.close()
                    inputStream.close()
                    result.success("Image saved to gallery")
                } ?: run {
                    result.error("ERROR", "Failed to save image", "Output stream is null")
                }
            } else {
                result.error("ERROR", "Failed to get image URI", null)
            }

        } catch (e: Exception) {
            result.error("ERROR", "Error saving image", e.message)
        }
    }
}
