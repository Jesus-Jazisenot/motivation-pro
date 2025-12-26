package com.example.motivation_pro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MotivationWidget : AppWidgetProvider() {

    companion object {
        private const val CHANNEL = "com.example.motivation_pro/widget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Crear intent para abrir la app al hacer tap
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Obtener frase desde SharedPreferences (actualizada por Flutter)
        val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        val quoteText = prefs.getString("quote_text", "Abre la app para ver tu frase del día") ?: ""
        val quoteAuthor = prefs.getString("quote_author", "Motivation PRO") ?: ""

        // Crear views del widget
        val views = RemoteViews(context.packageName, R.layout.motivation_widget).apply {
            setTextViewText(R.id.widget_quote_text, quoteText)
            setTextViewText(R.id.widget_quote_author, "- $quoteAuthor")
            setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        }

        // Actualizar widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onEnabled(context: Context) {
        // Widget añadido por primera vez
        updateWidgetQuote(context)
    }

    private fun updateWidgetQuote(context: Context) {
        val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        
        // Valores por defecto mientras Flutter se inicializa
        prefs.edit().apply {
            putString("quote_text", "Cargando tu frase del día...")
            putString("quote_author", "Motivation PRO")
            apply()
        }
    }
}