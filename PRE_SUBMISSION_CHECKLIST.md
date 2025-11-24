# 📱 Pre-Submission Checklist: iOS & Android

## 🎯 CRITICAL - Must Check Before Submission

### 1. App Version & Build Number ✅
- [ ] **iOS**: Update `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`
- [ ] **Android**: Update `versionName` and `versionCode` in `build.gradle`
- [ ] **Flutter**: Update `version` in `pubspec.yaml` (currently `0.0.1+9`)
- [ ] **Recommendation**: Use `1.0.0+1` for first production release

**Current Status**: `version: 0.0.1+9` in `pubspec.yaml`

---

## 🔧 FUNCTIONALITY CHECKS

### Authentication & User Management
- [ ] **Login Flow**
  - [ ] Login with valid credentials works
  - [ ] Login with invalid credentials shows proper error
  - [ ] "Forgot Password" flow works (if implemented)
  - [ ] Logout clears all user data
  - [ ] Session persistence works (app remembers login after restart)
  - [ ] Token refresh works correctly

- [ ] **User Profile**
  - [ ] Profile screen loads user data correctly
  - [ ] Profile image displays properly
  - [ ] Employee information is accurate
  - [ ] Profile updates (if any) work correctly

### Attendance Features
- [ ] **Check-In/Check-Out**
  - [ ] Location permission requested properly
  - [ ] GPS location captured accurately
  - [ ] Address reverse geocoding works
  - [ ] Check-in records location correctly
  - [ ] Check-out records location correctly
  - [ ] Location details modal shows correct info
  - [ ] Works when location services are disabled (shows error)
  - [ ] Works when location permission denied (shows error)
  - [ ] Works offline (shows error or queues request)

- [ ] **Attendance History**
  - [ ] Attendance history loads correctly
  - [ ] Date filtering works
  - [ ] History shows check-in/out times
  - [ ] Location data displays in history

### Leave Management
- [ ] **Leave Balance**
  - [ ] Leave balance displays correctly
  - [ ] Empty state shows properly (centered, professional)
  - [ ] Different leave types show correct balances
  - [ ] Balance updates after leave request

- [ ] **Leave Request**
  - [ ] Daily leave request submission works
  - [ ] Hourly leave request submission works
  - [ ] Date picker works correctly
  - [ ] Time picker works correctly
  - [ ] Shift data loads for selected date
  - [ ] File attachment upload works
  - [ ] Multiple file attachments work
  - [ ] File size validation (10MB limit) works
  - [ ] Warning modal for `WARNING_DAYS_VALIDATION` shows correctly
  - [ ] Remaining days warning shows correctly
  - [ ] Form validation works (required fields)
  - [ ] Success message shows after submission

- [ ] **Leave Approval** (for managers/HR)
  - [ ] Leave approval screen loads pending requests
  - [ ] Approve action works
  - [ ] Reject action works
  - [ ] Rejection reason input works
  - [ ] Approval workflow follows correct levels

- [ ] **Leave History**
  - [ ] Leave list loads correctly
  - [ ] Status filtering works
  - [ ] Leave details modal shows correctly
  - [ ] Status badges display correctly (pending/approved/rejected)

### Notifications
- [ ] **Push Notifications**
  - [ ] FCM token registration works
  - [ ] Push notifications received when app is open
  - [ ] Push notifications received when app is in background
  - [ ] Push notifications received when app is closed
  - [ ] Notification tap navigates to correct screen
  - [ ] Notification badge count updates correctly
  - [ ] Notification icons display correctly (calendar/check/cross)

- [ ] **In-App Notifications**
  - [ ] Notification list loads correctly
  - [ ] Unread count badge shows correctly
  - [ ] Mark as read works
  - [ ] Notification filtering works (own requests hidden)
  - [ ] Notification navigation works

### Settings
- [ ] **Settings Screen**
  - [ ] Language toggle works (Thai/English)
  - [ ] Privacy Policy link opens WebView
  - [ ] Logout works from settings
  - [ ] All settings options accessible

---

## 🎨 UI/UX CHECKS

### General UI
- [ ] **Splash Screen**
  - [ ] Splash screen displays correctly
  - [ ] No white screen flash
  - [ ] Smooth transition to login/home

- [ ] **Login Screen**
  - [ ] Logo displays correctly (rounded, with shadow)
  - [ ] No white space around logo
  - [ ] Form fields are accessible
  - [ ] Password visibility toggle works
  - [ ] Language toggle works
  - [ ] Keyboard doesn't cover input fields

- [ ] **Navigation**
  - [ ] Bottom navigation works correctly
  - [ ] All tabs accessible
  - [ ] Current tab highlighted correctly
  - [ ] Navigation state persists

- [ ] **Orientation**
  - [ ] App locked to portrait mode (iOS & Android)
  - [ ] No landscape mode issues
  - [ ] iPad multitasking orientations configured (iOS)

### Responsive Design
- [ ] **iOS Devices**
  - [ ] iPhone SE (small screen) - UI fits correctly
  - [ ] iPhone 14/15 (standard) - UI looks good
  - [ ] iPhone 14/15 Pro Max (large) - UI scales properly
  - [ ] iPad (if supported) - UI adapts correctly

- [ ] **Android Devices**
  - [ ] Small phones (5" screen) - UI fits correctly
  - [ ] Standard phones (6" screen) - UI looks good
  - [ ] Large phones (6.5"+ screen) - UI scales properly
  - [ ] Tablets (if supported) - UI adapts correctly

### Error States
- [ ] **Network Errors**
  - [ ] "No internet connection" message shows
  - [ ] Retry button works
  - [ ] Error messages are user-friendly (not technical)

- [ ] **Empty States**
  - [ ] "No data available" displays correctly (centered, professional)
  - [ ] Empty state icons display properly
  - [ ] Empty state messages are clear

- [ ] **Loading States**
  - [ ] Loading indicators show during API calls
  - [ ] No duplicate loading indicators
  - [ ] Loading states don't block UI unnecessarily

### Visual Polish
- [ ] **Colors & Themes**
  - [ ] Brand colors consistent throughout app
  - [ ] Dark mode works (if implemented)
  - [ ] Color contrast meets accessibility standards

- [ ] **Typography**
  - [ ] Text is readable on all screens
  - [ ] Font sizes appropriate
  - [ ] Thai and English text display correctly

- [ ] **Icons & Images**
  - [ ] All icons display correctly
  - [ ] Profile images load properly
  - [ ] App icon displays correctly on home screen
  - [ ] Notification icons are correct (calendar/check/cross)

---

## 🔒 SECURITY & PRIVACY CHECKS

### Permissions
- [ ] **Location Permission**
  - [ ] Permission requested at appropriate time
  - [ ] Permission denied handling works
  - [ ] Permission rationale explained to user
  - [ ] Settings deep link works (to enable permission)

- [ ] **Camera/Photo Permission**
  - [ ] Permission requested when needed
  - [ ] Permission denied handling works
  - [ ] Image picker works correctly

- [ ] **Notification Permission**
  - [ ] Permission requested appropriately
  - [ ] App works without notification permission

### Data Security
- [ ] **Sensitive Data**
  - [ ] No sensitive data in logs (✅ Already removed)
  - [ ] No API keys hardcoded
  - [ ] Tokens stored securely (SharedPreferences)
  - [ ] Tokens cleared on logout

- [ ] **Network Security**
  - [ ] HTTPS used for all API calls
  - [ ] Certificate pinning (if implemented) works
  - [ ] No HTTP calls in production

### Privacy Policy
- [ ] **Privacy Policy URL**
  - [ ] URL is publicly accessible: `https://nano-api-production.vercel.app/privacy-policy`
  - [ ] No login required to view
  - [ ] Available in both Thai and English
  - [ ] Covers: data collection, storage, usage, user rights
  - [ ] WebView opens correctly in app

---

## 📱 iOS-SPECIFIC CHECKS

### App Store Requirements
- [ ] **Info.plist Configuration**
  - [ ] `ITSAppUsesNonExemptEncryption = false` (if applicable)
  - [ ] `UISupportedInterfaceOrientations` configured
  - [ ] `UISupportedInterfaceOrientations~ipad` includes all 4 orientations
  - [ ] `NSLocationWhenInUseUsageDescription` present
  - [ ] `NSLocationAlwaysUsageDescription` present (if needed)
  - [ ] `NSCameraUsageDescription` present
  - [ ] `NSPhotoLibraryUsageDescription` present
  - [ ] `NSUserNotificationsUsageDescription` present

- [ ] **App Icons**
  - [ ] App icon 1024x1024 provided
  - [ ] All required icon sizes generated
  - [ ] Icon displays correctly on device

- [ ] **Build Configuration**
  - [ ] Release build configured
  - [ ] Code signing configured
  - [ ] Provisioning profile valid
  - [ ] Bundle ID matches App Store Connect

### iOS Functionality
- [ ] **Device Testing**
  - [ ] Tested on iPhone (physical device)
  - [ ] Tested on iPad (if supported)
  - [ ] Tested on iOS 15+
  - [ ] Tested on latest iOS version

- [ ] **iOS-Specific Features**
  - [ ] Push notifications work on iOS
  - [ ] Background location updates (if any) work
  - [ ] App badge updates correctly
  - [ ] App handles iOS background modes correctly

### App Store Connect
- [ ] **Metadata**
  - [ ] App name: "NANO Work"
  - [ ] Category: Business
  - [ ] Content rating: 4+
  - [ ] Keywords filled
  - [ ] Description filled (Thai & English)
  - [ ] Screenshots provided (all required sizes)
  - [ ] App preview video (optional but recommended)

- [ ] **App Privacy Details**
  - [ ] Location data collection declared
  - [ ] User content collection declared
  - [ ] Identifiers collection declared
  - [ ] Purpose for each data type explained

---

## 🤖 ANDROID-SPECIFIC CHECKS

### Google Play Requirements
- [ ] **build.gradle Configuration**
  - [ ] `versionCode` increments correctly
  - [ ] `versionName` set correctly
  - [ ] `minSdkVersion` appropriate (recommend 21+)
  - [ ] `targetSdkVersion` latest (33+)
  - [ ] `compileSdkVersion` latest

- [ ] **AndroidManifest.xml**
  - [ ] All permissions declared
  - [ ] `INTERNET` permission present
  - [ ] `ACCESS_FINE_LOCATION` permission present
  - [ ] `ACCESS_COARSE_LOCATION` permission present
  - [ ] `CAMERA` permission present (if needed)
  - [ ] `READ_EXTERNAL_STORAGE` permission present (if needed)
  - [ ] `WRITE_EXTERNAL_STORAGE` permission present (if needed)

- [ ] **App Icons**
  - [ ] Launcher icon 512x512 provided
  - [ ] Adaptive icon configured
  - [ ] Icon displays correctly on device

### Android Functionality
- [ ] **Device Testing**
  - [ ] Tested on Android phone (physical device)
  - [ ] Tested on Android tablet (if supported)
  - [ ] Tested on Android 8.0+ (API 26+)
  - [ ] Tested on latest Android version

- [ ] **Android-Specific Features**
  - [ ] Push notifications work on Android
  - [ ] Notification channels configured
  - [ ] Notification icons display correctly
  - [ ] App handles Android background restrictions

### Google Play Console
- [ ] **Store Listing**
  - [ ] App name: "NANO Work"
  - [ ] Category: Business
  - [ ] Content rating: Everyone
  - [ ] Short description (80 chars)
  - [ ] Full description (4000 chars)
  - [ ] Screenshots provided (phone, 7", 10")
  - [ ] Feature graphic provided

- [ ] **Data Safety Section**
  - [ ] Location data collection declared
  - [ ] Personal info collection declared
  - [ ] Photos collection declared
  - [ ] Device IDs collection declared
  - [ ] Purpose for each data type explained
  - [ ] Data sharing with third parties declared

---

## ⚡ PERFORMANCE CHECKS

### App Performance
- [ ] **Startup Time**
  - [ ] App launches in < 3 seconds
  - [ ] No white screen delay
  - [ ] Splash screen displays immediately

- [ ] **API Performance**
  - [ ] API calls complete in reasonable time
  - [ ] Slow API calls show loading indicators
  - [ ] API timeout handling works
  - [ ] Retry mechanism works for failed requests

- [ ] **Memory Usage**
  - [ ] No memory leaks
  - [ ] Images optimized (not too large)
  - [ ] Memory usage reasonable on low-end devices

- [ ] **Battery Usage**
  - [ ] Location services don't drain battery excessively
  - [ ] Background tasks optimized
  - [ ] Push notifications efficient

### Network Performance
- [ ] **Offline Handling**
  - [ ] App handles no internet gracefully
  - [ ] Error messages shown for network failures
  - [ ] Retry options available

- [ ] **Slow Network**
  - [ ] App works on 3G/4G
  - [ ] Loading states show during slow connections
  - [ ] Timeout handling works

---

## 🧪 TESTING CHECKLIST

### Manual Testing
- [ ] **Happy Path Testing**
  - [ ] Complete user journey: Login → Attendance → Leave → Notifications
  - [ ] All major features work end-to-end
  - [ ] No crashes during normal usage

- [ ] **Edge Cases**
  - [ ] Login with wrong password
  - [ ] Submit leave request with invalid data
  - [ ] Check-in without location permission
  - [ ] Upload very large file (>10MB)
  - [ ] Submit leave request with no internet
  - [ ] Navigate between screens rapidly

- [ ] **Error Scenarios**
  - [ ] API returns error
  - [ ] Network timeout
  - [ ] Permission denied
  - [ ] Invalid token (401 error)
  - [ ] Server error (500)

### Device Testing
- [ ] **iOS Devices**
  - [ ] iPhone SE (small screen)
  - [ ] iPhone 14/15 (standard)
  - [ ] iPhone 14/15 Pro Max (large)
  - [ ] iPad (if supported)

- [ ] **Android Devices**
  - [ ] Small phone (5" screen)
  - [ ] Standard phone (6" screen)
  - [ ] Large phone (6.5"+ screen)
  - [ ] Tablet (if supported)

### OS Version Testing
- [ ] **iOS**
  - [ ] iOS 15.0+
  - [ ] iOS 16.0+
  - [ ] Latest iOS version

- [ ] **Android**
  - [ ] Android 8.0 (API 26)
  - [ ] Android 10.0 (API 29)
  - [ ] Android 12.0+ (API 31+)
  - [ ] Latest Android version

---

## 📋 PRE-SUBMISSION FINAL CHECKS

### Code Quality
- [ ] **Logging**
  - [ ] All `print()` statements removed ✅ (Already done)
  - [ ] All `debugPrint()` statements removed ✅ (Already done)
  - [ ] All `kDebugMode` blocks removed ✅ (Already done)
  - [ ] No sensitive data in code

- [ ] **Build Configuration**
  - [ ] Release build compiles without errors
  - [ ] No debug flags enabled
  - [ ] ProGuard rules configured (Android)
  - [ ] Code obfuscation enabled (if needed)

### Documentation
- [ ] **App Store Listing**
  - [ ] Screenshots prepared (all required sizes)
  - [ ] App description written
  - [ ] Keywords selected
  - [ ] Support URL provided
  - [ ] Marketing URL provided (if any)

- [ ] **Privacy**
  - [ ] Privacy Policy URL live and accessible
  - [ ] Privacy Policy content complete
  - [ ] Data collection practices documented

### Final Build
- [ ] **iOS**
  - [ ] `flutter build ios --release` succeeds
  - [ ] Archive created in Xcode
  - [ ] Archive uploaded to App Store Connect
  - [ ] Build appears in TestFlight

- [ ] **Android**
  - [ ] `flutter build appbundle --release` succeeds
  - [ ] `.aab` file generated
  - [ ] `.aab` file uploaded to Google Play Console
  - [ ] Build appears in Play Console

---

## 🚨 COMMON REJECTION REASONS

### iOS App Store
- ❌ Missing privacy policy URL
- ❌ App crashes on launch
- ❌ Missing required permissions in Info.plist
- ❌ App doesn't work on required iOS versions
- ❌ Incomplete metadata (screenshots, description)
- ❌ App uses deprecated APIs

### Google Play Store
- ❌ Missing privacy policy URL
- ❌ App crashes on launch
- ❌ Missing Data Safety section
- ❌ App doesn't work on required Android versions
- ❌ Incomplete store listing
- ❌ App uses deprecated APIs

---

## ✅ PRIORITY ACTIONS

### Before First Submission:
1. ✅ **Remove all logging statements** (DONE)
2. ⚠️ **Update version to 1.0.0+1**
3. ⚠️ **Verify Privacy Policy URL is live**
4. ⚠️ **Test on physical devices (iOS & Android)**
5. ⚠️ **Prepare screenshots for both stores**
6. ⚠️ **Fill App Store Connect metadata**
7. ⚠️ **Fill Google Play Console metadata**
8. ⚠️ **Build release versions**
9. ⚠️ **Upload to both stores**
10. ⚠️ **Submit for review**

---

## 📝 NOTES

- App Store review: **1-3 days**
- Google Play review: **1-7 days**
- Both stores require active developer accounts:
  - iOS: **$99/year**
  - Android: **$25 one-time**

---

## 🎯 QUICK REFERENCE

### Build Commands:
```bash
# iOS
flutter build ios --release
# Then archive in Xcode

# Android
flutter build appbundle --release
```

### Current Version:
- `pubspec.yaml`: `0.0.1+9`
- **Recommended for production**: `1.0.0+1`

### Privacy Policy:
- URL: `https://nano-api-production.vercel.app/privacy-policy`
- **MUST be publicly accessible before submission**

---

**Last Updated**: Based on current codebase state
**Status**: Ready for testing, needs version update and final checks

