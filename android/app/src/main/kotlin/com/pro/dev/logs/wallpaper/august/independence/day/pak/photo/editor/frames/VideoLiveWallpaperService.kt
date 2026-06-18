package com.pro.dev.logs.wallpaper.august.independence.day.pak.photo.editor.frames

import android.content.Context
import android.media.MediaPlayer
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import java.io.File

class VideoLiveWallpaperService : WallpaperService() {
    override fun onCreateEngine(): Engine = VideoEngine()

    private inner class VideoEngine : Engine() {
        private var mediaPlayer: MediaPlayer? = null

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            startPlayer(holder)
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            stopPlayer()
            super.onSurfaceDestroyed(holder)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            super.onVisibilityChanged(visible)
            mediaPlayer?.let { player ->
                if (visible) {
                    if (!player.isPlaying) player.start()
                } else if (player.isPlaying) {
                    player.pause()
                }
            }
        }

        override fun onDestroy() {
            stopPlayer()
            super.onDestroy()
        }

        private fun startPlayer(holder: SurfaceHolder) {
            val path = getSource(applicationContext)
            if (path.isBlank() || !File(path).exists()) return

            stopPlayer()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(path)
                setSurface(holder.surface)
                isLooping = true
                setVolume(0f, 0f)
                setOnPreparedListener { it.start() }
                prepareAsync()
            }
        }

        private fun stopPlayer() {
            mediaPlayer?.run {
                try {
                    if (isPlaying) stop()
                } catch (_: IllegalStateException) {
                }
                reset()
                release()
            }
            mediaPlayer = null
        }
    }

    companion object {
        private const val prefsName = "video_live_wallpaper"
        private const val sourceKey = "source_path"

        fun setSource(context: Context, sourcePath: String) {
            context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .edit()
                .putString(sourceKey, sourcePath)
                .apply()
        }

        private fun getSource(context: Context): String {
            return context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .getString(sourceKey, "")
                .orEmpty()
        }
    }
}
