package com.pro.devlogs.pakistan.independence.photo.frames

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "wallpaper.apply/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "applyWallpaper" -> {
                        val imageUrl = call.argument<String>("imageUrl").orEmpty()
                        val target = call.argument<String>("target") ?: "both"

                        if (imageUrl.isBlank()) {
                            result.error(
                                "INVALID_IMAGE_URL",
                                "Wallpaper image URL is missing.",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        thread {
                            try {
                                val connection = URL(imageUrl).openConnection() as HttpURLConnection
                                connection.connectTimeout = 15000
                                connection.readTimeout = 30000
                                connection.instanceFollowRedirects = true
                                connection.connect()

                                if (connection.responseCode !in 200..299) {
                                    connection.disconnect()
                                    postError(
                                        result,
                                        "DOWNLOAD_FAILED",
                                        "Failed to download wallpaper.",
                                    )
                                    return@thread
                                }

                                val stream = BufferedInputStream(connection.inputStream)
                                val bitmap = BitmapFactory.decodeStream(stream)
                                stream.close()
                                connection.disconnect()

                                if (bitmap == null) {
                                    postError(
                                        result,
                                        "DECODE_FAILED",
                                        "Unable to decode wallpaper image.",
                                    )
                                    return@thread
                                }

                                val manager = WallpaperManager.getInstance(applicationContext)
                                when (target) {
                                    "home" -> {
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                            manager.setBitmap(
                                                bitmap,
                                                null,
                                                true,
                                                WallpaperManager.FLAG_SYSTEM,
                                            )
                                        } else {
                                            manager.setBitmap(bitmap)
                                        }
                                    }

                                    "lock" -> {
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                            manager.setBitmap(
                                                bitmap,
                                                null,
                                                true,
                                                WallpaperManager.FLAG_LOCK,
                                            )
                                        } else {
                                            postError(
                                                result,
                                                "UNSUPPORTED",
                                                "Lock screen apply needs Android 7.0+.",
                                            )
                                            return@thread
                                        }
                                    }

                                    else -> {
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                            manager.setBitmap(
                                                bitmap,
                                                null,
                                                true,
                                                WallpaperManager.FLAG_SYSTEM,
                                            )
                                            manager.setBitmap(
                                                bitmap,
                                                null,
                                                true,
                                                WallpaperManager.FLAG_LOCK,
                                            )
                                        } else {
                                            manager.setBitmap(bitmap)
                                        }
                                    }
                                }

                                Handler(Looper.getMainLooper()).post {
                                    result.success("Wallpaper applied successfully.")
                                }
                            } catch (error: Exception) {
                                postError(
                                    result,
                                    "APPLY_FAILED",
                                    error.localizedMessage ?: "Failed to apply wallpaper.",
                                )
                            }
                        }
                    }

                    "applyLiveWallpaper" -> {
                        val videoUrl = call.argument<String>("videoUrl").orEmpty()
                        val id = call.argument<String>("id").orEmpty()

                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN) {
                            result.error(
                                "UNSUPPORTED",
                                "Live wallpapers are not supported on this Android version.",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        if (videoUrl.isBlank() || id.isBlank()) {
                            result.error(
                                "INVALID_VIDEO_URL",
                                "Live wallpaper video URL is missing.",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        thread {
                            try {
                                val targetFile = File(filesDir, "live_wallpaper_$id.mp4")
                                val connection = URL(videoUrl).openConnection() as HttpURLConnection
                                connection.connectTimeout = 15000
                                connection.readTimeout = 30000
                                connection.instanceFollowRedirects = true
                                connection.connect()

                                if (connection.responseCode !in 200..299) {
                                    connection.disconnect()
                                    postError(
                                        result,
                                        "DOWNLOAD_FAILED",
                                        "Failed to download live wallpaper.",
                                    )
                                    return@thread
                                }

                                connection.inputStream.use { input ->
                                    FileOutputStream(targetFile).use { output ->
                                        input.copyTo(output)
                                    }
                                }
                                connection.disconnect()

                                VideoLiveWallpaperService.setSource(
                                    applicationContext,
                                    targetFile.absolutePath,
                                )

                                val intent = Intent(
                                    WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER,
                                ).apply {
                                    putExtra(
                                        WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                        ComponentName(
                                            this@MainActivity,
                                            VideoLiveWallpaperService::class.java,
                                        ),
                                    )
                                }

                                Handler(Looper.getMainLooper()).post {
                                    startActivity(intent)
                                    result.success(
                                        "Choose Set wallpaper on the next screen.",
                                    )
                                }
                            } catch (error: Exception) {
                                postError(
                                    result,
                                    "DOWNLOAD_FAILED",
                                    error.localizedMessage
                                        ?: "Failed to download live wallpaper.",
                                )
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String) {
        Handler(Looper.getMainLooper()).post {
            result.error(code, message, null)
        }
    }
}
