#!/bin/bash

# Build script for Magical Community Flutter App
# Usage: ./scripts/build.sh [android|ios|all] [debug|release]

set -e

PLATFORM=${1:-all}
BUILD_TYPE=${2:-release}

echo "🚀 Building Magical Community App"
echo "Platform: $PLATFORM"
echo "Build Type: $BUILD_TYPE"
echo "----------------------------------------"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Clean and get dependencies
print_status "Cleaning project..."
flutter clean

print_status "Getting dependencies..."
flutter pub get

# Run tests
print_status "Running tests..."
flutter test

# Build Android
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
    print_status "Building Android..."
    
    if [[ "$BUILD_TYPE" == "debug" ]]; then
        flutter build apk --debug
        print_status "Android debug APK built successfully!"
    else
        flutter build appbundle --release
        flutter build apk --release
        print_status "Android release bundle and APK built successfully!"
    fi
fi

# Build iOS
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "iOS builds require macOS. Skipping iOS build."
    else
        print_status "Building iOS..."
        
        # Install CocoaPods dependencies
        print_status "Installing CocoaPods dependencies..."
        cd ios
        pod install
        cd ..
        
        if [[ "$BUILD_TYPE" == "debug" ]]; then
            flutter build ios --debug --no-codesign
            print_status "iOS debug build completed successfully!"
        else
            flutter build ios --release --no-codesign
            print_status "iOS release build completed successfully!"
        fi
    fi
fi

print_status "Build process completed!"

# Show build artifacts
echo ""
echo "📦 Build Artifacts:"
echo "----------------------------------------"

if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
    if [[ "$BUILD_TYPE" == "debug" ]]; then
        if [[ -f "build/app/outputs/flutter-apk/app-debug.apk" ]]; then
            echo "Android Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
        fi
    else
        if [[ -f "build/app/outputs/bundle/release/app-release.aab" ]]; then
            echo "Android App Bundle: build/app/outputs/bundle/release/app-release.aab"
        fi
        if [[ -f "build/app/outputs/flutter-apk/app-release.apk" ]]; then
            echo "Android Release APK: build/app/outputs/flutter-apk/app-release.apk"
        fi
    fi
fi

if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]] && [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -d "build/ios/iphoneos/Runner.app" ]]; then
        echo "iOS App: build/ios/iphoneos/Runner.app"
    fi
fi

echo ""
print_status "All done! 🎉"
