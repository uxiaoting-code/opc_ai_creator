package com.example.opc_ai_creator

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "opc_ai_creator/media"
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveToGallery") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val bytes = call.argument<ByteArray>("bytes")
                    ?: throw IllegalArgumentException("缺少文件内容")
                val fileName = call.argument<String>("fileName")
                    ?: throw IllegalArgumentException("缺少文件名")
                val mimeType = call.argument<String>("mimeType")
                    ?: "application/octet-stream"
                result.success(saveToGallery(bytes, fileName, mimeType))
            } catch (error: Exception) {
                result.error("SAVE_FAILED", error.message, null)
            }
        }
    }

    private fun saveToGallery(bytes: ByteArray, fileName: String, mimeType: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val isVideo = mimeType.startsWith("video/")
            val collection = if (isVideo) {
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
            val relativePath = if (isVideo) {
                "${Environment.DIRECTORY_MOVIES}/OPC AI"
            } else {
                "${Environment.DIRECTORY_PICTURES}/OPC AI"
            }
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("无法创建相册文件")
            resolver.openOutputStream(uri).use { output ->
                requireNotNull(output) { "无法打开相册文件" }.write(bytes)
            }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        }

        val directory = if (mimeType.startsWith("video/")) {
            getExternalFilesDir(Environment.DIRECTORY_MOVIES)
        } else {
            getExternalFilesDir(Environment.DIRECTORY_PICTURES)
        } ?: filesDir
        directory.mkdirs()
        val target = File(directory, fileName)
        target.writeBytes(bytes)
        return target.absolutePath
    }
}
