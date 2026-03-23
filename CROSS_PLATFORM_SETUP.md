# Cross-Platform Setup Instructions

This document provides instructions for setting up the Magical Community Flutter project on different platforms.

## Prerequisites

- Flutter SDK (latest stable version)
- Git
- Platform-specific tools (see below)

## Initial Setup (All Platforms)

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd magical_community
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Clean any existing build artifacts:
   ```bash
   flutter clean
   ```

## iOS Setup (macOS only)

1. Install Xcode from the App Store
2. Install CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```
3. Navigate to the iOS directory and install pods:
   ```bash
   cd ios
   pod install
   ```
4. Open the project in Xcode:
   ```bash
   open Runner.xcworkspace
   ```

## Android Setup

1. Install Android Studio
2. Install Android SDK and accept licenses:
   ```bash
   flutter doctor --android-licenses
   ```
3. Build the project:
   ```bash
   flutter build apk --debug
   ```

## Windows Setup

1. Install Visual Studio with C++ development tools
2. Enable Windows development:
   ```bash
   flutter config --enable-windows-desktop
   ```
3. Build for Windows:
   ```bash
   flutter build windows
   ```

## Troubleshooting

### Issue: "Failed to load container" error on macOS
This usually happens when moving the project between different machines or platforms.

**Solution:**
1. Clean Flutter artifacts:
   ```bash
   flutter clean
   ```
2. Remove iOS build artifacts:
   ```bash
   cd ios
   rm -rf Pods .symlinks build
   ```
3. Reinstall dependencies:
   ```bash
   cd ..
   flutter pub get
   cd ios
   pod install
   ```

### Issue: Platform-specific path errors
This happens when absolute paths from one platform are cached in build artifacts.

**Solution:**
1. Never commit the following files/directories:
   - `ios/Flutter/Generated.xcconfig`
   - `ios/Flutter/flutter_export_environment.sh`
   - `ios/.symlinks/`
   - `ios/Pods/`
   - `ios/**/xcuserdata/`
   - `android/local.properties`

2. Always run `flutter clean` when switching between platforms or machines.

## Development Workflow

1. Always run `flutter clean` when:
   - Switching between different machines
   - Moving between different platforms (Windows ↔ macOS)
   - Encountering build errors
   - After pulling changes that might affect build configuration

2. Use `flutter doctor` to verify your setup:
   ```bash
   flutter doctor -v
   ```

3. For iOS development, always use the `.xcworkspace` file, not the `.xcodeproj` file.

## Important Notes

- The `Generated.xcconfig` file contains platform-specific absolute paths and should never be committed to version control
- Always use relative paths in configuration files
- CocoaPods dependencies are platform-specific and should be regenerated on each machine
- Build artifacts should always be cleaned when moving between platforms
