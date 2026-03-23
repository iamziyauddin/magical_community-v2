# Build Commands (Windows CMD)

This project supports dev and prod builds via `--dart-define=ENVIRONMENT`. Use these copy-paste commands in Windows CMD.

## Paths
- Project root: `F:\Flutter\FlutterProjects\MyMagicalCommunity\magical_community`
- AAB: `build\app\outputs\bundle\release\app-release.aab`
- APK (debug): `build\app\outputs\flutter-apk\app-debug.apk`
- APK (release): `build\app\outputs\flutter-apk\app-release.apk`

## Dev Builds

- Dev Debug APK (fast for local testing)
```bat
cd /d F:\Flutter\FlutterProjects\MyMagicalCommunity\magical_community
flutter build apk --debug --dart-define=ENVIRONMENT=dev
```

- Dev App Bundle (rarely needed, for parity testing)
```bat
cd /d F:\Flutter\FlutterPro--dart-define=ENVIRONMENT=devjects\MyMagicalCommunity\magical_community
flutter build appbundle --dart-define=ENVIRONMENT=dev
```

## Prod Builds

- Release App Bundle (Play Store)
```bat
cd /d F:\Flutter\FlutterProjects\MyMagicalCommunity\magical_community
flutter build appbundle --dart-define=ENVIRONMENT=prod
```

- Release APK (sideload testing)
```bat
cd /d F:\Flutter\FlutterProjects\MyMagicalCommunity\magical_community
flutter build apk --release c
```

## Clean/Repair (if builds fail)

- Clean project and re-fetch deps
```bat
cd /d F:\Flutter\FlutterProjects\MyMagicalCommunity\magical_community
flutter clean
flutter pub get
```

- Full pub cache reset (fixes corrupted cache errors)
```bat
cd /d F:\Flutter\FlutterProjects\MyMagicalCommunity\magical_community
echo y | flutter pub cache clean
flutter pub get
```

## Notes
- Env switching is controlled by `--dart-define=ENVIRONMENT=dev|prod` and `Env` in `lib/core/config/env.dart`.
- Prod AAB is signed using the keystore configured in `android/key.properties` (points to `storeconfiq/magical-community-key.jks`).
- If Windows shows asset copy collisions (errno 183), delete `build\app\intermediates\flutter\release\flutter_assets` and rebuild.
