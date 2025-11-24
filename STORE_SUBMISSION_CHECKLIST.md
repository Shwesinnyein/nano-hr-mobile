# 📱 Store Submission Checklist for NANO Work - HR Management

## ✅ Code Changes (COMPLETED)
- [x] Added Privacy Policy link in Settings
- [x] Privacy Settings now opens: `https://nano-api-production.vercel.app/privacy-policy`

## 🔴 CRITICAL - Before Submitting

### 1. Privacy Policy URL (REQUIRED) 🔒
**Status**: ⚠️ **NEEDS ACTION**

Make sure this URL is **publicly accessible**:
- `https://nano-api-production.vercel.app/privacy-policy`
- **NO login required** to view
- Must be in both Thai and English
- Should cover: data collection, storage, usage, user rights

**Quick Test**: Open the URL in incognito mode to verify no auth required.

---

### 2. Update Version Number
**Current**: `0.0.1+1`

Before release, update in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Major.Minor.Patch+Build
```

---

### 3. App Icons & Assets
✅ Icon configured: `assets/icon/nano-icon-square.png`
- **iOS**: 1024x1024 (required)
- **Android**: 512x512 (recommended)

---

## 📱 App Store (iOS) Submission

### Required Information:

1. **App Name**: NANO Work (or NANO HR)
2. **Category**: Business
3. **Content Rating**: 4+ (Business apps are usually 4+)
4. **Keywords**: HR, payroll, attendance, leave management, employee
5. **Privacy Policy URL**: https://nano-api-production.vercel.app/privacy-policy
6. **Support URL**: https://nano-api-production.vercel.app/contact
7. **Marketing URL** (optional): Your website

### App Privacy Details (REQUIRED in App Store Connect):

Answer these questions about data collection:

1. **Does your app collect location data?** 
   - ✅ YES (for attendance check-in/check-out)
   - Purpose: Attendance tracking
   - User location: Checked in times only

2. **Does your app collect user content?**
   - ✅ YES (profile photos, documents)

3. **Does your app collect identifiers?**
   - ✅ YES (Employee ID, Device ID)

4. **Does your app collect health and fitness data?**
   - ❌ NO

### Build Steps for iOS:
```bash
flutter build ios --release
# Then archive in Xcode
# Upload to App Store Connect
```

---

## 🤖 Google Play Store Submission

### Required Information:

1. **App Name**: NANO Work
2. **Category**: Business
3. **Content Rating**: Everyone (Business apps)
4. **Privacy Policy URL**: https://nano-api-production.vercel.app/privacy-policy
5. **Contact Email**: Your support email

### Data Safety Section (REQUIRED):

Declare what data you collect:

1. **Location**: 
   - ✅ Collected: Approximate location, precise location
   - Purpose: Attendance tracking
   - Shared with third parties: NO

2. **Personal Info**:
   - ✅ Employee ID, Name, Email, Phone

3. **Photos**:
   - ✅ Profile photos

4. **Device or other IDs**:
   - ✅ Device ID

### Build Steps for Android:
```bash
flutter build appbundle --release
# Upload .aab file to Google Play Console
```

---

## 📋 Store Listing Requirements

### Screenshots Needed:
- **iOS**: iPhone 6.7", 6.5", 5.5"
- **Android**: Phone, 7", 10"

### Short Description (80 chars):
"HR management app for attendance, leave, payroll, and employee data."

### Full Description:
```
NANO Work is a comprehensive HR management mobile application that helps organizations manage their workforce efficiently. 

Features:
- 📍 Location-based attendance tracking
- 📅 Leave request management with multi-level approvals
- 📊 Real-time attendance history and reports
- 👥 Employee directory and profiles
- 🔔 Push notifications for important updates
- 💼 Payroll and salary information
- 🌐 Multi-language support (Thai/English)
- 🔒 Secure and private

Perfect for modern HR departments looking to streamline employee management.
```

---

## 🔧 Pre-Submission Testing

### Test on Real Devices:
- [ ] Test on at least 2 different iPhone models
- [ ] Test on at least 2 different Android devices
- [ ] Test with bad network (3G, offline)
- [ ] Test with location services disabled
- [ ] Test with camera permissions denied

### Key Features to Test:
- [ ] Login/Logout
- [ ] Attendance check-in/out
- [ ] Leave request submission
- [ ] Notifications
- [ ] Profile view
- [ ] Employee directory
- [ ] Privacy Policy link

---

## 🚀 Submission Steps

### For iOS (App Store):
1. Build release: `flutter build ios --release`
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Archive: Product → Archive
4. Upload to App Store Connect
5. Fill metadata in App Store Connect
6. Submit for review

### For Android (Google Play):
1. Build release: `flutter build appbundle --release`
2. Go to Google Play Console
3. Create new app or select existing
4. Upload .aab file
5. Fill store listing
6. Fill Data Safety section
7. Submit for review

---

## 📝 Notes

- ⚠️ **Privacy Policy URL MUST be live before submission**
- App Store review takes 1-3 days
- Google Play review takes 1-7 days
- Both stores require active developer accounts ($99/year each)

---

## 🎯 Priority Actions

1. ✅ **URGENT**: Make Privacy Policy URL publicly accessible
2. Update app version to 1.0.0
3. Test thoroughly on physical devices
4. Prepare screenshots and descriptions
5. Build release versions
6. Submit to both stores

