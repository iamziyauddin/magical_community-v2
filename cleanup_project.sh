#!/bin/bash

# Cross-platform Flutter project cleanup script
# Run this script when moving the project between different machines or platforms

echo "Starting Flutter project cleanup..."

# Clean Flutter artifacts
echo "Cleaning Flutter artifacts..."
flutter clean

# Remove iOS build artifacts if on macOS or if ios directory exists
if [ -d "ios" ]; then
    echo "Cleaning iOS artifacts..."
    cd ios
    if [ -d "Pods" ]; then
        rm -rf Pods
        echo "Removed Pods directory"
    fi
    if [ -d ".symlinks" ]; then
        rm -rf .symlinks
        echo "Removed .symlinks directory"
    fi
    if [ -d "build" ]; then
        rm -rf build
        echo "Removed iOS build directory"
    fi
    # Remove user-specific Xcode files
    find . -name "*.xcuserstate" -delete
    find . -name "xcuserdata" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pbxuser" -delete
    find . -name "*.mode1v3" -delete
    find . -name "*.mode2v3" -delete
    find . -name "*.perspectivev3" -delete
    echo "Removed user-specific Xcode files"
    cd ..
fi

# Remove Android build artifacts
if [ -d "android" ]; then
    echo "Cleaning Android artifacts..."
    cd android
    if [ -d "build" ]; then
        rm -rf build
        echo "Removed Android build directory"
    fi
    if [ -d "app/build" ]; then
        rm -rf app/build
        echo "Removed Android app build directory"
    fi
    # Remove local.properties which contains machine-specific paths
    if [ -f "local.properties" ]; then
        rm local.properties
        echo "Removed local.properties"
    fi
    cd ..
fi

# Remove Windows build artifacts
if [ -d "windows" ]; then
    echo "Cleaning Windows artifacts..."
    cd windows
    if [ -d "build" ]; then
        rm -rf build
        echo "Removed Windows build directory"
    fi
    cd ..
fi

# Remove macOS build artifacts
if [ -d "macos" ]; then
    echo "Cleaning macOS artifacts..."
    cd macos
    if [ -d "Pods" ]; then
        rm -rf Pods
        echo "Removed macOS Pods directory"
    fi
    if [ -d ".symlinks" ]; then
        rm -rf .symlinks
        echo "Removed macOS .symlinks directory"
    fi
    if [ -d "build" ]; then
        rm -rf build
        echo "Removed macOS build directory"
    fi
    cd ..
fi

# Remove web build artifacts
if [ -d "web" ]; then
    echo "Cleaning web artifacts..."
    cd web
    if [ -f "flutter_service_worker.js" ]; then
        rm flutter_service_worker.js
        echo "Removed flutter_service_worker.js"
    fi
    cd ..
fi

# Remove general build directory
if [ -d "build" ]; then
    rm -rf build
    echo "Removed main build directory"
fi

# Reinstall Flutter dependencies
echo "Reinstalling Flutter dependencies..."
flutter pub get

echo "Cleanup completed! The project is now ready for cross-platform development."
echo ""
echo "Next steps:"
echo "- For iOS: cd ios && pod install (macOS only)"
echo "- For Android: flutter doctor --android-licenses (if needed)"
echo "- Run 'flutter doctor' to verify your setup"
