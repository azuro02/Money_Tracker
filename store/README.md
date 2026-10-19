# Store release

Everything needed for the Google Play and App Store listings.

Icons, feature graphics and screenshots are generated locally and are not
part of the repository.

## Google Play

1. Signing: `android/key.properties` points to the upload keystore (not in
   git). **Back up the keystore and key.properties** (e.g. password manager).
   With Play App Signing a lost upload key can be reset, but it takes days.
2. Build: `flutter build appbundle --release`
   → `build/app/outputs/bundle/release/app-release.aab`
3. Play Console → create app → upload the AAB to *Internal testing* first.
   New personal developer accounts must run a closed test with at least 12
   testers for 14 days before production access.
4. Store listing: texts from `listing_*.md`, icon, feature graphic,
   screenshots (phone required, tablets optional).
5. App content:
   - Privacy policy URL:
     `https://github.com/azuro02/Money_Tracker/blob/main/PRIVACY.md`
   - Ads: no.
   - Data safety: *No data collected, no data shared.* Data is not
     transmitted off the device (the app has no internet permission).
   - Content rating questionnaire: category "Utility/Productivity", answer
     everything with "no" → rated for all ages.
   - Target audience: 18+ (avoids the extra requirements for apps aimed at
     children).
   - Financial features declaration: the app only records numbers the user
     types in; it moves no real money, offers no loans and connects to no
     bank. Pick the option that matches that (personal budgeting / none).
   - Permissions: `USE_BIOMETRIC`, `POST_NOTIFICATIONS`,
     `RECEIVE_BOOT_COMPLETED` (daily reminder).

## App Store (requires a Mac with Xcode)

1. Apple Developer Program membership, bundle ID
   `de.moneytracker.app` registered.
2. `flutter build ipa --release`, upload with Transporter or Xcode.
3. App Store Connect: texts from `listing_*.md`, screenshots for iPhone 6.9"
   and iPad 13" (smaller sizes are scaled automatically).
4. App privacy: "Data not collected".
5. Export compliance: the app encrypts backups with AES (standard
   algorithm, user's own data). Answer the encryption questions accordingly.
6. Privacy policy URL as for Google Play.
