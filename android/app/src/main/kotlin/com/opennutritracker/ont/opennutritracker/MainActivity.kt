package com.opennutritracker.ont.opennutritracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.atlastracker.android/nutrition_widget").setMethodCallHandler { call, result ->
            if (call.method == "update") {
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
