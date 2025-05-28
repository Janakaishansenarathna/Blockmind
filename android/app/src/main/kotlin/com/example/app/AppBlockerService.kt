package com.example.app

import android.app.Activity
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AppBlockerService(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.example.socialmediablocker/app_blocker"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "hasUsageStatsPermission" -> result.success(hasUsageStatsPermission())
            "getCurrentForegroundApp" -> result.success(getCurrentForegroundApp())
            "blockApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(blockApp(packageName))
                } else {
                    result.error("INVALID_ARGUMENTS", "Package name is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getCurrentForegroundApp(): String? {
        if (!hasUsageStatsPermission()) {
            return null
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        
        // Get usage stats for the last minute
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, time - 60 * 1000, time
        )
        
        // Find the most recent app
        return stats.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    private fun blockApp(packageName: String): Boolean {
        // In a real implementation, this would show an overlay to block access
        // For now, just return true as a placeholder
        return true
    }
}