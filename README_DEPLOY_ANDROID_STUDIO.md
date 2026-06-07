# Android Studio deployment steps

This is now an Android Studio–ready Flutter project.

## Very important Firebase step

This project uses Android package name:

```text
com.schengenvisaalerts.app
```

In Firebase Console, add a new Android app with this exact package name, then download:

```text
google-services.json
```

Put it here:

```text
android/app/google-services.json
```

If you use your old Firebase Android app package name, push notifications may not work.

## Open in Android Studio

1. Extract this ZIP.
2. Open Android Studio.
3. Click **Open**.
4. Select the folder:

```text
schengen_visa_alerts
```

5. Wait until Gradle/Flutter sync finishes.
6. Open Android Studio Terminal and run:

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
```

APK path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Build Play Store AAB

```bash
flutter build appbundle --release
```

AAB path:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Firebase required settings

Enable these in Firebase:

1. Authentication → Sign-in method → Email/Password
2. Firestore Database
3. Cloud Messaging

## Firestore collections used

### users

Each user document should have:

```json
{
  "uid": "user id",
  "email": "customer email",
  "name": "customer name",
  "subscriptionStatus": "active",
  "selectedCountry": "All",
  "selectedCentre": "All",
  "fcmToken": "device token"
}
```

### alerts

Your bot/backend should create documents like:

```json
{
  "alert_type": "NEW",
  "country": "Netherlands",
  "centre": "London",
  "category": "Tourism",
  "earliest": "15 June 2026",
  "booking_link": "https://wa.me/+447426416286",
  "createdAt": "server timestamp"
}
```

## Stripe link

Edit this file:

```text
lib/main.dart
```

Search:

```text
oneCountryLink
allCountriesLink
```

Replace with your real Stripe monthly payment links.

## Branding removed

All Fastest Travel branding has been removed. App name is:

```text
Schengen Visa Alerts UK
```
