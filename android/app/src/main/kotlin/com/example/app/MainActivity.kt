package com.example.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the AppBlockerService method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, 
                     AppBlockerService.CHANNEL).setMethodCallHandler(
            AppBlockerService(context)
        )
    }
}