package com.example.motivation_pro

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.motivation_pro/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getQuote" -> {
                    // Flutter maneja esto, solo confirmamos
                    result.success(null)
                }
                "updateWidget" -> {
                    val text = call.argument<String>("text") ?: ""
                    val author = call.argument<String>("author") ?: ""
                    updateWidget(text, author)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun updateWidget(text: String, author: String) {
        val prefs = getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("quote_text", text)
            putString("quote_author", author)
            apply()
        }

        // Forzar actualización del widget
        val intent = Intent(this, MotivationWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val ids = AppWidgetManager.getInstance(application)
            .getAppWidgetIds(ComponentName(application, MotivationWidget::class.java))
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        sendBroadcast(intent)
    }
}