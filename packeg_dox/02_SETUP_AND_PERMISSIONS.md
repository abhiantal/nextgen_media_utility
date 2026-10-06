# 02 — Setup & Platform Permissions 🛠️

Follow this guide to configure Android and iOS platforms before running the package in your Flutter project.

---

## 1. Add Dependency

In your project's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  nextgen_media_utility:
    git:
      url: https://github.com/abhiantal/nextgen_media_utility.git
      ref: main
```

*(Or once published to pub.dev: `nextgen_media_utility: ^0.0.1`)*

### ⚠️ Material Icons Bundling Requirement
Ensure your `pubspec.yaml` has `uses-material-design: true` enabled:
```yaml
flutter:
  uses-material-design: true
```
> If omitted, Flutter does not bundle `MaterialIcons-Regular.otf` into the APK, causing camera and editor icons to appear as empty boxes or tofu symbols.

---

## 2. Android Configuration

### A. AndroidManifest.xml (`android/app/src/main/AndroidManifest.xml`)

Add the required permissions inside the `<manifest>` tag, and include `xmlns:tools="http://schemas.android.com/tools"`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.yourcompany.yourapp">

    <!-- Camera Access -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Audio Recording -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Gallery & Storage (Android 12 and below) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission 
        android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
        android:maxSdkVersion="29" 
        tools:replace="android:maxSdkVersion" />

    <!-- Gallery Media Permissions (Android 13+ / API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

    <application
        android:label="Your App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">
        ...
    </application>
</manifest>
```

> **Why `tools:replace="android:maxSdkVersion"`?**
> Newer Android permission libraries enforce `maxSdkVersion="32"`, while legacy media packages specify `29`. The `tools:replace` attribute cleanly resolves the Android Manifest Merger conflict without compilation errors.

### B. App Build Gradle (`android/app/build.gradle` or `build.gradle.kts`)

Ensure your `compileSdk` and `minSdk` meet modern Android requirements:

```kotlin
android {
    compileSdk = 35 // Or 34+

    defaultConfig {
        minSdk = 24  // Recommended minSdk for camera and video processing
        targetSdk = 35
    }
}
```

---

## 3. iOS Configuration

### A. Info.plist (`ios/Runner/Info.plist`)

Add the following permission description strings inside the `<dict>` tag:

```xml
<!-- Camera Access -->
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to take photos and record videos.</string>

<!-- Microphone Access -->
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record voice notes and video audio.</string>

<!-- Photo Library Access -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to pick images and videos.</string>

<!-- Photo Library Save Access (Gal) -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs permission to save edited photos and videos to your photo album.</string>
```

### B. Podfile (`ios/Podfile`)

Ensure platform target is at least iOS 13.0:

```ruby
platform :ios, '13.0'
```

And in the `post_install` block, enable camera and photo permissions for CocoaPods:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

---

## 4. Verify Installation

Run:
```bash
flutter pub get
flutter run
```
Your app is now fully configured to use all camera, gallery, audio, and compression tools!
