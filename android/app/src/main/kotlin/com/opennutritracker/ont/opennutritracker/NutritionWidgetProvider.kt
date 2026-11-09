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
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.text.style.StyleSpan
import android.graphics.Typeface
import android.util.AtomicFile
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.File
import java.text.DateFormat
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.roundToLong

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
            val format = NumberFormat.getIntegerInstance()
            fun number(key: String) = data?.optDouble(key, 0.0)?.takeIf { it.isFinite() } ?: 0.0
            fun value(key: String) = if (fresh) format.format(number(key)) else "—"
            views.setTextViewText(R.id.widget_status, when {
                data == null -> context.getString(R.string.widget_sign_in)
                !fresh -> context.getString(R.string.widget_refresh)
                else -> DateFormat.getDateInstance(DateFormat.MEDIUM).format(Calendar.getInstance().time)
            })
            val remaining = number("kcalGoal").roundToLong() - number("kcal").roundToLong()
            val remainingValue = if (fresh) format.format(kotlin.math.abs(remaining)) else "—"
            val headline = SpannableString("$remainingValue kcal")
            headline.setSpan(RelativeSizeSpan(0.5f), headline.length - 4, headline.length,
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            headline.setSpan(StyleSpan(Typeface.BOLD), headline.length - 4, headline.length,
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            views.setTextViewText(R.id.widget_kcal, headline)
            views.setTextViewText(R.id.widget_energy_label, context.getString(
                if (fresh && remaining < 0) R.string.widget_energy_over_label else R.string.widget_energy_remaining_label))
            views.setTextViewText(R.id.widget_kcal_consumed, value("kcal"))
            views.setTextViewText(R.id.widget_kcal_goal, value("kcalGoal"))
            for ((id, key) in listOf(R.id.widget_carbs_value to "carbs",
                    R.id.widget_fats_value to "fats", R.id.widget_protein_value to "proteins")) {
                views.setTextViewText(id, if (fresh) "${value(key)} / ${value("${key}Goal")} g" else "— g")
            }
            for ((id, key) in listOf(R.id.widget_kcal_bar to "kcal", R.id.widget_carbs_bar to "carbs",
                    R.id.widget_fats_bar to "fats", R.id.widget_protein_bar to "proteins")) {
                val goal = number("${key}Goal")
                val progress = if (fresh && goal > 0)
                    (number(key) / goal * 1000).coerceIn(0.0, 1000.0).toInt() else 0
                views.setProgressBar(id, 1000, progress, false)
            }
            val summary = if (fresh) {
                context.getString(if (remaining >= 0) R.string.widget_remaining else R.string.widget_over,
                    format.format(kotlin.math.abs(remaining))) + ", " +
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
            views.setContentDescription(R.id.widget_summary, summary)
            val launch = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            views.setOnClickPendingIntent(R.id.widget_root,
                PendingIntent.getActivity(context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            for ((id, action) in listOf(R.id.widget_scan to "scan", R.id.widget_add to "add")) {
                val intent = Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    .putExtra("nutrition_widget_action", action)
                views.setOnClickPendingIntent(id,
                    PendingIntent.getActivity(context, if (action == "scan") 1 else 2, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            }
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
