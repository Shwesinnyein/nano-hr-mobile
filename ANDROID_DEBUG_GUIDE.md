# Android Installation & Debugging Guide

## Prerequisites
- Android device connected via USB or wireless debugging
- USB debugging enabled on your Android device
- Developer options enabled on your Android device

## Quick Start

### 1. Install & Run on Android Device

**From Terminal:**
```bash
# Run on connected Android device
flutter run -d adb-R58N219ZEMR-su6JmL._adb-tls-connect._tcp

# Or let Flutter auto-select the device
flutter run
```

**With Hot Reload:**
- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### 2. Debug Mode (Recommended)

**Run in Debug Mode:**
```bash
flutter run --debug -d adb-R58N219ZEMR-su6JmL._adb-tls-connect._tcp
```

**Or with verbose logging:**
```bash
flutter run --debug -v -d adb-R58N219ZEMR-su6JmL._adb-tls-connect._tcp
```

### 3. View Logs While Debugging

**Option A: In the same terminal where you ran `flutter run`**
- Logs appear automatically in the terminal

**Option B: Separate terminal for logs only**
```bash
# In a new terminal window
flutter logs
```

**Option C: Using adb logcat directly**
```bash
# View all Flutter logs
adb logcat | grep -E "flutter|dart"

# View notification-related logs
adb logcat | grep -iE "notification|🔔|📨|📬|PERM|SHOW|FOREGROUND|FCM"

# View with timestamps
adb logcat -v time | grep -E "flutter|dart|notification"
```

### 4. Using Android Studio

1. **Open Project in Android Studio:**
   - File → Open → Select `nano-hr-mobile` folder
   - Wait for Gradle sync to complete

2. **Select Device:**
   - Top toolbar: Select "samsung SM-G985F" from device dropdown
   - Or: Run → Select Device → Choose your device

3. **Run/Debug:**
   - Click the green "Run" button (▶️) or press `Shift+F10`
   - Or click the "Debug" button (🐛) or press `Shift+F9`

4. **View Logs in Logcat:**
   - View → Tool Windows → Logcat
   - Or click "Logcat" tab at bottom of Android Studio
   - Filter by: `flutter` or `notification`

5. **Set Breakpoints:**
   - Click left margin next to line number to set breakpoint
   - Run in Debug mode (🐛 button)
   - App will pause at breakpoints

### 5. Debug Notification Issues

**Check Permission Status:**
```bash
adb shell dumpsys package com.nano.hr | grep permission
```

**Check Notification Channels:**
```bash
adb shell dumpsys notification | grep -A 10 "nano_hr_foreground"
```

**Test Notification Permission:**
```bash
adb shell pm grant com.nano.hr android.permission.POST_NOTIFICATIONS
```

### 6. Common Debugging Commands

**List connected devices:**
```bash
flutter devices
adb devices
```

**Uninstall app (fresh start):**
```bash
adb uninstall com.nano.hr
```

**Clear app data:**
```bash
adb shell pm clear com.nano.hr
```

**Install APK directly:**
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**View app info:**
```bash
adb shell dumpsys package com.nano.hr | grep -A 5 "permissions"
```

### 7. Enable USB Debugging on Android Device

If device not detected:

1. **Enable Developer Options:**
   - Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back → Developer Options

2. **Enable USB Debugging:**
   - Settings → Developer Options
   - Enable "USB Debugging"
   - Enable "Wireless Debugging" (for wireless connection)

3. **Authorize Computer:**
   - When connecting, accept "Allow USB Debugging" prompt on phone

### 8. Wireless Debugging (Android 11+)

1. **On Phone:**
   - Settings → Developer Options → Wireless Debugging
   - Note the IP address and port

2. **On Computer:**
   ```bash
   adb connect <IP_ADDRESS>:<PORT>
   ```

3. **Verify Connection:**
   ```bash
   adb devices
   ```

### 9. Debug Notification Flow

**Step-by-step debugging:**

1. **Start app in debug mode:**
   ```bash
   flutter run --debug -v
   ```

2. **Watch for initialization logs:**
   - Look for `🔔 [INIT]` messages
   - Check if permissions are granted: `🔔 [PERM]`

3. **Send test notification:**
   - Use your backend/admin panel
   - Or use Firebase Console

4. **Watch foreground logs:**
   - Look for `📨 [FOREGROUND]` messages
   - Check `🔔 [SHOW]` for display attempts
   - Look for `✅` or `❌` messages

5. **Check Android Logcat:**
   ```bash
   adb logcat | grep -E "🔔|📨|notification|FCM"
   ```

### 10. Troubleshooting

**Device not detected:**
```bash
# Restart adb server
adb kill-server
adb start-server
adb devices
```

**App won't install:**
```bash
# Uninstall existing version first
adb uninstall com.nano.hr
flutter run
```

**Logs not showing:**
- Make sure you're in debug mode (not release)
- Check that `kDebugMode` is true in your code
- Verify device is selected in Android Studio

**Notifications not working:**
- Check Android 13+ notification permission
- Verify notification channel is created
- Check Firebase configuration
- Review Logcat for error messages

## Quick Reference

| Action | Command |
|--------|---------|
| Run app | `flutter run` |
| Run on specific device | `flutter run -d <device-id>` |
| View logs | `flutter logs` |
| Hot reload | Press `r` in terminal |
| Hot restart | Press `R` in terminal |
| Quit | Press `q` in terminal |
| Build debug APK | `flutter build apk --debug` |
| List devices | `flutter devices` |
| Clear app data | `adb shell pm clear com.nano.hr` |

