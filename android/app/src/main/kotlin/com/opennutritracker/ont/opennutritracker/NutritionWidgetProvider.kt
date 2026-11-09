package com.opennutritracker.ont.opennutritracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.util.AtomicFile
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class NutritionWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        updateAll(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager,
        id: Int, options: Bundle) {
        updateAll(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in listOf(MIDNIGHT, Intent.ACTION_DATE_CHANGED,
                Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
                Intent.ACTION_LOCALE_CHANGED)) updateAll(context)
    }

    override fun onDisabled(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(midnightIntent(context))
    }

    companion object {
        private const val MIDNIGHT = "com.atlastracker.android.WIDGET_NEW_DAY"

        // Nutrition summaries stay on this device and are excluded from backups.
        private fun storage(context: Context) =
            AtomicFile(File(context.noBackupFilesDir, "nutrition_widget.json"))

        fun save(context: Context, data: Map<*, *>?) {
            val file = storage(context)
            if (data == null) {
                file.delete()
            } else {
                val json = JSONObject()
                data.forEach { (key, value) -> json.put(key.toString(), value) }
                val output = file.startWrite()
                try {
                    output.write(json.toString().toByteArray(Charsets.UTF_8))
                    file.finishWrite(output)
                } catch (error: Exception) {
                    file.failWrite(output)
                    throw error
                }
            }
            updateAll(context)
        }

        private fun midnightIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(context, 0,
                Intent(context, NutritionWidgetProvider::class.java).setAction(MIDNIGHT),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, NutritionWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val data = try {
                storage(context).openRead().use { JSONObject(it.readBytes().toString(Charsets.UTF_8)) }
            } catch (_: Exception) { null }
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(Calendar.getInstance().time)
            val fresh = data != null && data.optString("date") == today
            val views = RemoteViews(context.packageName, R.layout.nutrition_widget)
            views.setImageViewBitmap(R.id.widget_artwork,
                NutritionWidgetArtwork.render(context, data, fresh))
            val summary = if (fresh) {
                val format = java.text.NumberFormat.getIntegerInstance()
                listOf("kcal", "carbs", "fats", "proteins").joinToString(", ") { key ->
                    val label = when (key) {
                        "carbs" -> context.getString(R.string.widget_carbs)
                        "fats" -> context.getString(R.string.widget_fats)
                        "proteins" -> context.getString(R.string.widget_proteins)
                        else -> "kcal"
                    }
                    "$label ${format.format(data!!.optDouble(key, 0.0))} / ${format.format(data.optDouble("${key}Goal", 0.0))}"
                }
            } else context.getString(if (data == null) R.string.widget_sign_in else R.string.widget_refresh)
            views.setContentDescription(R.id.widget_root, summary)
            val launch = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            views.setOnClickPendingIntent(R.id.widget_root,
                PendingIntent.getActivity(context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            manager.updateAppWidget(ids, views)
            // Inexact alarm: no exact-alarm permission or constantly running service.
            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_MONTH, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, midnight.timeInMillis, midnightIntent(context))
            } else {
                alarms.set(AlarmManager.RTC_WAKEUP, midnight.timeInMillis, midnightIntent(context))
            }
        }
    }
}
