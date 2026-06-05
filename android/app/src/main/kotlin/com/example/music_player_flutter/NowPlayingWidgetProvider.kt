package com.example.music_player_flutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.view.KeyEvent
import android.widget.RemoteViews
import java.io.File

class NowPlayingWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.music_player_flutter.PLAY_PAUSE"
        const val ACTION_SKIP_NEXT  = "com.example.music_player_flutter.SKIP_NEXT"
        const val ACTION_SKIP_PREV  = "com.example.music_player_flutter.SKIP_PREV"
        private const val PREFS_NAME = "HomeWidgetPlugin"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) updateWidget(context, appWidgetManager, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_PLAY_PAUSE -> sendMediaKey(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            ACTION_SKIP_NEXT  -> sendMediaKey(context, KeyEvent.KEYCODE_MEDIA_NEXT)
            ACTION_SKIP_PREV  -> sendMediaKey(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
        }
    }

    // Forwards a media key to audio_service's MediaButtonReceiver so the
    // widget buttons work even without opening the app.
    private fun sendMediaKey(context: Context, keyCode: Int) {
        for (action in listOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            val i = Intent(Intent.ACTION_MEDIA_BUTTON)
            i.setClass(context, com.ryanheise.audioservice.MediaButtonReceiver::class.java)
            i.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(action, keyCode))
            context.sendBroadcast(i)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title     = prefs.getString("title",     null) ?: context.getString(R.string.widget_not_playing)
        val artist    = prefs.getString("artist",    "") ?: ""
        val isPlaying = prefs.getBoolean("is_playing", false)
        val artPath   = prefs.getString("art_path",  null)

        val views = RemoteViews(context.packageName, R.layout.now_playing_widget)

        views.setTextViewText(R.id.widget_title,  title)
        views.setTextViewText(R.id.widget_artist, artist)
        views.setImageViewResource(
            R.id.widget_play_pause,
            if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_widget_play
        )

        // Album art: show cached bitmap if available, else music-note placeholder
        if (!artPath.isNullOrEmpty()) {
            val f = File(artPath)
            if (f.exists()) {
                val bmp = BitmapFactory.decodeFile(artPath)
                if (bmp != null) {
                    views.setImageViewBitmap(R.id.widget_art, bmp)
                } else {
                    views.setImageViewResource(R.id.widget_art, R.drawable.ic_widget_music)
                }
            } else {
                views.setImageViewResource(R.id.widget_art, R.drawable.ic_widget_music)
            }
        } else {
            views.setImageViewResource(R.id.widget_art, R.drawable.ic_widget_music)
        }

        // Tap card → open app
        val openApp = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_art,    openApp)
        views.setOnClickPendingIntent(R.id.widget_title,  openApp)
        views.setOnClickPendingIntent(R.id.widget_artist, openApp)

        views.setOnClickPendingIntent(
            R.id.widget_play_pause,
            broadcastIntent(context, ACTION_PLAY_PAUSE, 1)
        )
        views.setOnClickPendingIntent(
            R.id.widget_next,
            broadcastIntent(context, ACTION_SKIP_NEXT, 2)
        )
        views.setOnClickPendingIntent(
            R.id.widget_prev,
            broadcastIntent(context, ACTION_SKIP_PREV, 3)
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun broadcastIntent(context: Context, action: String, reqCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context, reqCode,
            Intent(context, NowPlayingWidgetProvider::class.java).apply { this.action = action },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
}
