package com.nano.hr

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "MyFirebaseMessaging"
        private const val CHANNEL_ID = "high_importance_channel"
    }

    // Track processed messages to prevent duplicates
    private val processedMessages = mutableSetOf<String>()
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.e(TAG, "🔔 [NATIVE] onMessageReceived called")
        Log.e(TAG, "🔔 [NATIVE] MessageId: ${remoteMessage.messageId}")
        Log.e(TAG, "🔔 [NATIVE] From: ${remoteMessage.from}")
        Log.e(TAG, "🔔 [NATIVE] Has notification: ${remoteMessage.notification != null}")
        Log.e(TAG, "🔔 [NATIVE] Data: ${remoteMessage.data}")

        // CRITICAL: Prevent duplicates - check if already processed
        val messageId = remoteMessage.messageId ?: System.currentTimeMillis().toString()
        if (processedMessages.contains(messageId)) {
            Log.e(TAG, "⚠️ [NATIVE] Duplicate message detected, skipping: $messageId")
            return
        }
        processedMessages.add(messageId)
        
        // Clean up old message IDs (keep only last 100)
        if (processedMessages.size > 100) {
            val toRemove = processedMessages.take(20).toSet()
            processedMessages.removeAll(toRemove)
        }

        // CRITICAL: When app is in foreground, Flutter's onMessage handles notifications
        // Native service should ONLY show for background/paused/terminated states
        // However, we can't easily detect app state from native service
        // So we'll show notification, but Flutter's duplicate prevention should catch it
        
        // Extract title and body
        var title: String? = null
        var body: String? = null

        // First try notification block
        remoteMessage.notification?.let { notification ->
            title = notification.title
            body = notification.body
            Log.e(TAG, "🔔 [NATIVE] From notification block - Title: $title, Body: $body")
        }

        // If no notification block, try data payload
        if (title == null || body == null) {
            val data = remoteMessage.data
            title = data["title"]?.toString() 
                ?: data["notification_title"]?.toString()
                ?: "NANO Work"
            
            body = data["body"]?.toString()
                ?: data["message"]?.toString()
                ?: data["notification_body"]?.toString()
                ?: "New notification"
            
            Log.e(TAG, "🔔 [NATIVE] From data payload - Title: $title, Body: $body")
        }

        // CRITICAL FIX FOR DUPLICATE NOTIFICATIONS ON ANDROID:
        // Native service should NOT show notifications when Flutter can handle them
        // 
        // iOS works because: iOS automatically shows notifications when notification block exists
        // Android doesn't: Both native and Flutter show, causing duplicates
        //
        // Solution: Disable native service completely - let Flutter handle everything
        // - Flutter's onMessage handles foreground (including paused)
        // - Flutter's background handler handles terminated state
        // This matches iOS behavior where only one service shows notifications
        
        Log.e(TAG, "ℹ️ [NATIVE] Skipping native notification - Flutter will handle it")
        Log.e(TAG, "ℹ️ [NATIVE] This prevents duplicate notifications on Android (like iOS)")
        
        // Don't show notification - Flutter handles all cases
        return
    }

    override fun handleIntent(intent: Intent?) {
        Log.e(TAG, "🔔 [NATIVE] handleIntent called")
        // Don't show notification here - onMessageReceived already handles it
        // This prevents duplicate notifications
        super.handleIntent(intent)
    }

    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        try {
            createNotificationChannel()

            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                data.forEach { (key, value) ->
                    putExtra(key, value)
                }
            }

            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.nano_notification)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setOnlyAlertOnce(false) // Alert every time
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val notificationId = System.currentTimeMillis().toInt()
            
            notificationManager.notify(notificationId, notificationBuilder.build())
            Log.e(TAG, "✅ [NATIVE] Notification shown - ID: $notificationId, Title: $title")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [NATIVE] Error showing notification: ${e.message}", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_MAX
            ).apply {
                description = "Used for essential notifications."
                enableVibration(true)
                enableLights(true)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
            Log.e(TAG, "✅ [NATIVE] Notification channel created: $CHANNEL_ID")
        }
    }

    override fun onNewToken(token: String) {
        Log.e(TAG, "🔔 [NATIVE] New FCM token: $token")
        super.onNewToken(token)
    }
}

