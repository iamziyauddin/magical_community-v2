# PowerShell script to build signed App Bundle for Google Play Store
Write-Host "Building Magical Community App - Signed App Bundle for Google Play Store" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan

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
Write-Host "- Build Type: App Bundle (AAB) - Signed" -ForegroundColor Yellow
Write-Host "- Target: Google Play Store" -ForegroundColor Yellow
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

# Build signed App Bundle with production environment
Write-Host "Building signed App Bundle for production environment..." -ForegroundColor Green
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

& flutter build appbundle --release --dart-define=ENVIRONMENT=prod --dart-define=API_BASE_URL=https://api.magicalcommunity.in/api/rest

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Green
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "=======================================================================" -ForegroundColor Green
    Write-Host ""
    
    # Get AAB path
    $aabPath = "build\app\outputs\bundle\release\app-release.aab"
    
    if (Test-Path $aabPath) {
        $aabInfo = Get-Item $aabPath
        Write-Host "App Bundle Details:" -ForegroundColor Cyan
        Write-Host "- File: $($aabInfo.FullName)" -ForegroundColor White
        Write-Host "- Size: $([math]::Round($aabInfo.Length / 1MB, 2)) MB" -ForegroundColor White
        Write-Host "- Created: $($aabInfo.CreationTime)" -ForegroundColor White
        Write-Host ""
        
        # Create a timestamped copy for distribution
        $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
        $distributionPath = "MagicalCommunity-PlayStore-v$timestamp.aab"
        Copy-Item $aabPath $distributionPath -Force
        
        Write-Host "Distribution Copy Created:" -ForegroundColor Green
        Write-Host "- $distributionPath" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Upload to Google Play Console" -ForegroundColor White
        Write-Host "2. Test on internal testing track" -ForegroundColor White
        Write-Host "3. Promote to closed/open testing when ready" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Google Play Console Upload Steps:" -ForegroundColor Yellow
        Write-Host "1. Go to Google Play Console" -ForegroundColor White
        Write-Host "2. Select your app" -ForegroundColor White
        Write-Host "3. Go to Release > Testing > Internal testing" -ForegroundColor White
        Write-Host "4. Create new release" -ForegroundColor White
        Write-Host "5. Upload the AAB file: $distributionPath" -ForegroundColor White
        Write-Host "6. Add release notes" -ForegroundColor White
        Write-Host "7. Review and roll out" -ForegroundColor White
    } else {
        Write-Host "Warning: AAB file not found at expected location" -ForegroundColor Yellow
        Write-Host "Check build/app/outputs/bundle/release/ directory" -ForegroundColor Yellow
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
