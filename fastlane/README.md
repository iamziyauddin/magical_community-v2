# Fastlane Documentation

This document describes how to use Fastlane for automated building and deployment of the Magical Community Flutter app.

## Prerequisites

### For Android:
- Google Play Console access
- Service account JSON key file
- Android SDK and build tools

### For iOS (requires macOS):
- Apple Developer account
- Xcode installed
- CocoaPods installed (`sudo gem install cocoapods`)
- Fastlane installed (`sudo gem install fastlane`)

## Setup

1. **Install dependencies:**
   ```bash
   # On macOS
   bundle install
   
   # On Windows (Android only)
   # Install Ruby and run: gem install fastlane
   ```

2. **Configure credentials:**
   - Update `fastlane/Appfile` with your Apple ID and team IDs
   - Place Google Play service account JSON in project root
   - Update paths in `fastlane/Appfile`

3. **Setup code signing (iOS only):**
   ```bash
   # Initialize match for certificate management
   fastlane match init
   
   # Generate certificates and profiles
   fastlane match appstore
   fastlane match development
   ```

## Available Lanes

### Android

- **`fastlane android debug`** - Build debug APK
- **`fastlane android beta`** - Build and upload to Firebase App Distribution
- **`fastlane android deploy`** - Build and upload to Google Play Console

### iOS (macOS only)

- **`fastlane ios development`** - Build development IPA
- **`fastlane ios beta`** - Build and upload to TestFlight
- **`fastlane ios deploy`** - Build and upload to App Store

## Usage Examples

```bash
# Build Android debug
fastlane android debug

# Deploy to Google Play internal track
fastlane android deploy

# Upload iOS to TestFlight (macOS only)
fastlane ios beta

# Deploy iOS to App Store (macOS only)
fastlane ios deploy
```

## Environment Variables

Create a `.env` file in the fastlane directory for sensitive data:

```
APPLE_ID=your-apple-id@example.com
ITC_TEAM_ID=123456789
TEAM_ID=8YDZ48SP5U
MATCH_PASSWORD=your-match-password
FIREBASE_APP_ID=1:123456789:android:abcd1234
```

## CI/CD Integration

This Fastlane setup supports CI/CD with GitHub Actions, Azure DevOps, or similar platforms. Set environment variables in your CI system and use:

```bash
# For CI environments
fastlane ios beta --env ci
fastlane android deploy --env ci
```

## Troubleshooting

### iOS Build Issues:
- Ensure you're on macOS with Xcode installed
- Run `pod install` in the ios directory
- Verify certificates with `fastlane match development --readonly`

### Android Build Issues:
- Verify Android SDK installation with `flutter doctor`
- Check Google Play Console permissions
- Ensure service account JSON has correct permissions

## Security Notes

- Never commit `.env` files or service account keys to version control
- Use CI/CD environment variables for sensitive data
- Store certificates in a private repository when using match
