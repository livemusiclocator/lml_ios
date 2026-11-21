# Live Music Locator for iOS

A SwiftUI client for the same read-only gigs API as `lml_frontend_client`.

The Xcode project is generated, not committed:

```
brew install xcodegen
xcodegen generate
open LML.xcodeproj
```

## Running on a phone

The simulator needs no setup. To put the app on your own phone, tell Xcode who
signs it:

```
cp Config/Signing.local.example.xcconfig Config/Signing.local.xcconfig
```

Then edit `Config/Signing.local.xcconfig` (git ignores it):

- `DEVELOPMENT_TEAM`: your team ID, from Xcode > Settings > Accounts. A free
  Apple ID works, but its builds stop opening after 7 days.
- `LML_BUNDLE_ID`: `au.com.livemusiclocator.app` is registered to Mark's team,
  so outside that team use your own, e.g. `au.com.livemusiclocator.app.yourname`.

Run `xcodegen generate` again, connect the phone, and run the LML scheme on it.
