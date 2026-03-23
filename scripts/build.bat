@echo off
REM Build script for Magical Community Flutter App on Windows
REM Usage: scripts\build.bat [android] [debug|release] [env]
REM Example (release prod): scripts\build.bat android release prod

setlocal enabledelayedexpansion

set PLATFORM=%1
set BUILD_TYPE=%2
set ENVIRONMENT=%3

if "%PLATFORM%"=="" set PLATFORM=android
if "%BUILD_TYPE%"=="" set BUILD_TYPE=release
if "%ENVIRONMENT%"=="" set ENVIRONMENT=prod

echo 🚀 Building Magical Community App
echo Platform: %PLATFORM%
echo Build Type: %BUILD_TYPE%
echo Env: %ENVIRONMENT%
echo ----------------------------------------

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed or not in PATH
    exit /b 1
)

REM Clean and get dependencies
echo ✅ Cleaning project...
flutter clean

echo ✅ Getting dependencies...
flutter pub get

REM Run tests
echo ✅ Running tests...
flutter test

REM Build Android only (iOS requires macOS)
if /i "%PLATFORM%"=="android" (
    echo ✅ Building Android...
    
    if /i "%BUILD_TYPE%"=="debug" (
        flutter build apk --debug
        echo ✅ Android debug APK built successfully!
    ) else (
    flutter build appbundle --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
    flutter build apk --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
        echo ✅ Android release bundle and APK built successfully!
    )
) else (
    echo ⚠️  iOS builds require macOS. Only Android builds are supported on Windows.
    echo ⚠️  Use the macOS build script or GitHub Actions for iOS builds.
)

echo.
echo 📦 Build Artifacts:
echo ----------------------------------------

if /i "%BUILD_TYPE%"=="debug" (
    if exist "build\app\outputs\flutter-apk\app-debug.apk" (
        echo Android Debug APK: build\app\outputs\flutter-apk\app-debug.apk
    )
) else (
    if exist "build\app\outputs\bundle\release\app-release.aab" (
        echo Android App Bundle: build\app\outputs\bundle\release\app-release.aab
    )
    if exist "build\app\outputs\flutter-apk\app-release.apk" (
        echo Android Release APK: build\app\outputs\flutter-apk\app-release.apk
    )
)

echo.
echo ✅ All done! 🎉

endlocal
