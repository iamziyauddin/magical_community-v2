# PowerShell script to build signed APK for internal testing
Write-Host "Building Magical Community App - Signed Release for Internal Testing" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (!(Test-Path "pubspec.yaml")) {
    Write-Host "Error: This script should be run from the Flutter project root directory" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if keystore exists
if (!(Test-Path "android/app/magical-community-key.jks")) {
    Write-Host "Error: Keystore file not found at android/app/magical-community-key.jks" -ForegroundColor Red
    Write-Host "Please run create_keystore.ps1 first to create the keystore" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if key.properties exists
if (!(Test-Path "android/key.properties")) {
    Write-Host "Error: key.properties file not found at android/key.properties" -ForegroundColor Red
    Write-Host "Please ensure key.properties file exists with correct passwords" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Green
Write-Host "- Environment: PRODUCTION" -ForegroundColor Yellow
Write-Host "- Build Type: Release (Signed)" -ForegroundColor Yellow
Write-Host "- Target: Internal Testing" -ForegroundColor Yellow
Write-Host "- API URL: https://api.magicalcommunity.in/api/rest" -ForegroundColor Yellow
Write-Host ""

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Blue
& flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter clean failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Blue
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter pub get failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Build signed APK with production environment
Write-Host "Building signed APK for production environment..." -ForegroundColor Green
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

& flutter build apk --release --dart-define=ENVIRONMENT=prod --dart-define=API_BASE_URL=https://api.magicalcommunity.in/api/rest

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host ""
    
    # Get APK path
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    
    if (Test-Path $apkPath) {
        $apkInfo = Get-Item $apkPath
        Write-Host "APK Details:" -ForegroundColor Cyan
        Write-Host "- File: $($apkInfo.FullName)" -ForegroundColor White
        Write-Host "- Size: $([math]::Round($apkInfo.Length / 1MB, 2)) MB" -ForegroundColor White
        Write-Host "- Created: $($apkInfo.CreationTime)" -ForegroundColor White
        Write-Host ""
        
        # Create a timestamped copy for distribution
        $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
        $distributionPath = "MagicalCommunity-Internal-v$timestamp.apk"
        Copy-Item $apkPath $distributionPath -Force
        
        Write-Host "Distribution Copy Created:" -ForegroundColor Green
        Write-Host "- $distributionPath" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Test the APK on a physical device" -ForegroundColor White
        Write-Host "2. Share with internal testers" -ForegroundColor White
        Write-Host "3. Upload to Google Play Console for internal testing track" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Commands for testing:" -ForegroundColor Yellow
        Write-Host "- Install on connected device: flutter install --release" -ForegroundColor White
        Write-Host "- Or manually install: adb install -r `"$distributionPath`"" -ForegroundColor White
    } else {
        Write-Host "Warning: APK file not found at expected location" -ForegroundColor Yellow
        Write-Host "Check build/app/outputs/flutter-apk/ directory" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    Write-Host "Please check the error messages above and fix any issues." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "- Incorrect passwords in android/key.properties" -ForegroundColor White
    Write-Host "- Missing keystore file" -ForegroundColor White
    Write-Host "- Build configuration errors" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to exit"
