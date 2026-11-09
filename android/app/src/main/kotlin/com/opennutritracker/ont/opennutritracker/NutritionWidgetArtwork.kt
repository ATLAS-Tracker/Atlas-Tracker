package com.opennutritracker.ont.opennutritracker

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.Typeface
import org.json.JSONObject
import java.text.DateFormat
import java.text.NumberFormat
import java.util.Date
import kotlin.math.abs
import kotlin.math.roundToLong

/** Coordinates follow the 1080 × 540 card in widget-style-preview.png. */
internal object NutritionWidgetArtwork {
    fun render(context: Context, data: JSONObject?, fresh: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap(1080, 540, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.typeface = Typeface.createFromAsset(context.assets, "flutter_assets/fonts/Poppins-ExtraBold.ttf")
        val format = NumberFormat.getIntegerInstance()
        fun number(key: String) = data?.optDouble(key, 0.0)?.takeIf { it.isFinite() } ?: 0.0
        fun value(key: String) = if (fresh) format.format(number(key)) else "—"
        fun rounded(x: Float, y: Float, w: Float, h: Float, radius: Float, color: Int) {
            paint.color = color
            canvas.drawRoundRect(x, y, x + w, y + h, radius, radius, paint)
        }
        fun text(value: String, x: Float, baseline: Float, size: Float, color: Int, maxWidth: Float) {
            paint.color = color
            paint.textSize = size
            val width = paint.measureText(value)
            if (width > maxWidth) paint.textSize = size * maxWidth / width
            canvas.drawText(value, x, baseline, paint)
        }
        fun bar(key: String, x: Float, y: Float, color: Int, track: Int) {
            rounded(x, y, 450f, 27f, 13.5f, track)
            val goal = number("${key}Goal")
            val fraction = if (fresh && goal > 0) (number(key) / goal).coerceIn(0.0, 1.0) else 0.0
            if (fraction > 0) rounded(x, y, 450f * fraction.toFloat(), 27f, 13.5f, color)
        }
        val white = Color.WHITE
        val ink = Color.rgb(15, 17, 22)
        rounded(0f, 0f, 1080f, 540f, 76f, Color.rgb(221, 230, 245))
        rounded(3f, 3f, 1074f, 534f, 73f, white)
        paint.shader = LinearGradient(20f, 20f, 542f, 518f,
            Color.rgb(4, 84, 242), Color.rgb(0, 63, 206), Shader.TileMode.CLAMP)
        canvas.drawRoundRect(20f, 20f, 542f, 518f, 64f, 64f, paint)
        paint.shader = null
        paint.color = 0x0DFFFFFF
        canvas.drawCircle(386f, 176f, 132f, paint)
        val status = when {
            data == null -> context.getString(R.string.widget_sign_in)
            !fresh -> context.getString(R.string.widget_refresh)
            else -> DateFormat.getDateInstance(DateFormat.MEDIUM).format(Date())
        }
        text(status, 56f, 87f, 32f, white, 450f)
        text(value("kcal"), 46f, 240f, 112f, white, 460f)
        text(if (fresh) context.getString(R.string.widget_kcal_goal, value("kcalGoal")) else "kcal",
            56f, 313f, 36f, white, 450f)
        bar("kcal", 56f, 349f, white, 0x4DFFFFFF)
        if (fresh) {
            val remaining = number("kcalGoal").roundToLong() - number("kcal").roundToLong()
            text(context.getString(if (remaining >= 0) R.string.widget_remaining else R.string.widget_over,
                format.format(abs(remaining))), 56f, 452f, 36f, white, 450f)
        }
        val macros = listOf(
            Triple("carbs", R.string.widget_carbs, 0xFFF5A610.toInt()),
            Triple("fats", R.string.widget_fats, 0xFF12B894.toInt()),
            Triple("proteins", R.string.widget_proteins, 0xFF2276FA.toInt()))
        for ((index, macro) in macros.withIndex()) {
            val (key, label, color) = macro
            val y = index * 158f
            text(context.getString(label), 578f, 75f + y, 34f, ink, 450f)
            text(if (fresh) "${value(key)} / ${value("${key}Goal")} g" else "— g",
                578f, 130f + y, 40f, ink, 450f)
            bar(key, 578f, 154f + y, color, when (key) {
                "carbs" -> 0xFFFDF2DC.toInt()
                "fats" -> 0xFFDCF4EF.toInt()
                else -> 0xFFDDEAFF.toInt()
            })
        }
        return bitmap
    }
}
