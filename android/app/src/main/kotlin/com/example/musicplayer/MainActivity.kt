package com.example.musicplayer

import android.content.Context
import android.database.Cursor
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.proplayer.app/video_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupMethodChannel(flutterEngine)
    }

    private fun setupMethodChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "queryVideos") {
                try {
                    result.success(queryMediaStoreVideos())
                } catch (e: Exception) {
                    result.error("VIDEO_QUERY_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun queryMediaStoreVideos(): List<Map<String, Any?>> {
        val videos = mutableListOf<Map<String, Any?>>()
        val collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.TITLE,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_MODIFIED,
            MediaStore.Video.Media.DATE_ADDED,
        )
        val sortOrder = "${MediaStore.Video.Media.DATE_MODIFIED} DESC"

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(collection, projection, null, null, sortOrder)
            cursor?.use { c ->
                val idCol = c.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
                val titleCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.TITLE)
                val dataCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
                val durCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
                val sizeCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
                val modCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_MODIFIED)
                val addCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)

                while (c.moveToNext()) {
                    val id = c.getLong(idCol)
                    val title = c.getString(titleCol) ?: "Unknown"
                    val data = c.getString(dataCol) ?: continue
                    val duration = c.getInt(durCol)
                    val size = c.getLong(sizeCol)
                    val dateModified = c.getLong(modCol) * 1000L
                    val dateAdded = c.getLong(addCol) * 1000L

                    videos.add(mapOf(
                        "id" to id.toString(),
                        "title" to title,
                        "path" to data,
                        "duration" to duration,
                        "size" to size,
                        "dateModified" to dateModified,
                        "dateAdded" to dateAdded,
                    ))
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return videos
    }
}
