package com.opennutritracker.ont.opennutritracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var pendingWidgetAction: String? = null

    private fun readWidgetAction(intent: Intent) {
        val action = intent.getStringExtra("nutrition_widget_action")
        intent.removeExtra("nutrition_widget_action")
        if (action == "scan" || action == "add") pendingWidgetAction = action
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readWidgetAction(intent)
        if (pendingWidgetAction != null) widgetChannel?.invokeMethod("actionAvailable", null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        readWidgetAction(intent)
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.atlastracker.android/nutrition_widget")
        widgetChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "takeAction") {
                val action = pendingWidgetAction
                pendingWidgetAction = null
                result.success(action)
            } else if (call.method == "update") {
                try {
                    NutritionWidgetProvider.save(this, call.arguments as? Map<*, *>)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("widget_update", error.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
