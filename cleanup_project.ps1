# Cross-platform Flutter project cleanup script for Windows PowerShell
# Run this script when moving the project between different machines or platforms

Write-Host "Starting Flutter project cleanup..." -ForegroundColor Green

# Clean Flutter artifacts
Write-Host "Cleaning Flutter artifacts..." -ForegroundColor Yellow
flutter clean

# Remove iOS build artifacts if ios directory exists
if (Test-Path "ios") {
    Write-Host "Cleaning iOS artifacts..." -ForegroundColor Yellow
    Set-Location ios
    
    if (Test-Path "Pods") {
        Remove-Item -Recurse -Force "Pods"
        Write-Host "Removed Pods directory" -ForegroundColor Gray
    }
    
    if (Test-Path ".symlinks") {
        Remove-Item -Recurse -Force ".symlinks"
        Write-Host "Removed .symlinks directory" -ForegroundColor Gray
    }
    
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Host "Removed iOS build directory" -ForegroundColor Gray
    }
    
    # Remove user-specific Xcode files
    Get-ChildItem -Recurse -Include "*.xcuserstate" | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Recurse -Directory -Name "xcuserdata" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Get-ChildItem -Recurse -Include "*.pbxuser", "*.mode1v3", "*.mode2v3", "*.perspectivev3" | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "Removed user-specific Xcode files" -ForegroundColor Gray
    
    Set-Location ..
}

# Remove Android build artifacts
if (Test-Path "android") {
    Write-Host "Cleaning Android artifacts..." -ForegroundColor Yellow
    Set-Location android
    
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Host "Removed Android build directory" -ForegroundColor Gray
    }
    
    if (Test-Path "app\build") {
        Remove-Item -Recurse -Force "app\build"
        Write-Host "Removed Android app build directory" -ForegroundColor Gray
    }
    
    # Remove local.properties which contains machine-specific paths
    if (Test-Path "local.properties") {
        Remove-Item -Force "local.properties"
        Write-Host "Removed local.properties" -ForegroundColor Gray
    }
    
    Set-Location ..
}

# Remove Windows build artifacts
if (Test-Path "windows") {
    Write-Host "Cleaning Windows artifacts..." -ForegroundColor Yellow
    Set-Location windows
    
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Host "Removed Windows build directory" -ForegroundColor Gray
    }
    
    Set-Location ..
}

# Remove macOS build artifacts
if (Test-Path "macos") {
    Write-Host "Cleaning macOS artifacts..." -ForegroundColor Yellow
    Set-Location macos
    
    if (Test-Path "Pods") {
        Remove-Item -Recurse -Force "Pods"
        Write-Host "Removed macOS Pods directory" -ForegroundColor Gray
    }
    
    if (Test-Path ".symlinks") {
        Remove-Item -Recurse -Force ".symlinks"
        Write-Host "Removed macOS .symlinks directory" -ForegroundColor Gray
    }
    
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Host "Removed macOS build directory" -ForegroundColor Gray
    }
    
    Set-Location ..
}

# Remove web build artifacts
if (Test-Path "web") {
    Write-Host "Cleaning web artifacts..." -ForegroundColor Yellow
    Set-Location web
    
    if (Test-Path "flutter_service_worker.js") {
        Remove-Item -Force "flutter_service_worker.js"
        Write-Host "Removed flutter_service_worker.js" -ForegroundColor Gray
    }
    
    Set-Location ..
}

# Remove general build directory
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
    Write-Host "Removed main build directory" -ForegroundColor Gray
}

# Reinstall Flutter dependencies
Write-Host "Reinstalling Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Cleanup completed! The project is now ready for cross-platform development." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "- For iOS: cd ios && pod install (macOS only)" -ForegroundColor White
Write-Host "- For Android: flutter doctor --android-licenses (if needed)" -ForegroundColor White
Write-Host "- Run 'flutter doctor' to verify your setup" -ForegroundColor White
