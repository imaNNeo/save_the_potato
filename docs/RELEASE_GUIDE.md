Steps to release a version:

1. Create a new branch with this pattern: `release/x.y.z`
2. Update the version name and version code in the pubspec.yaml
3. Replace `newVersion` with the version that you decided in the CHANGELOG.md
4. Update the `assets/texts/release_notes.json` file to put the release notes
5. Commit and push the changes with a message like this: `Bump version to x.y.z`
6. Go to the repository [releases section](https://github.com/imaNNeo/save_the_potato/releases) and create a new release. Create a tag for it with this pattern: `x.y.z` (exactly the version name in `pubspec.yaml`) and **choose the branch that you created in the first step as the Target branch**.
7. Copy and paste the latest changelog from [CHANGELOG.md](https://github.com/imaNNeo/save_the_potato/blob/main/CHANGELOG.md) file into the description field.
8. Then publish the release. It triggers the [release workflow](https://github.com/imaNNeo/save_the_potato/blob/main/.github/workflows/release.yml), which:
   - fails early if the tag doesn't match the `pubspec.yaml` version or a secret is missing,
   - uploads the Android app bundle to the Play **internal** track, with the release notes from `release_notes.json`,
   - uploads the iOS build to **TestFlight**,
   - attaches the `.aab`, `.apk` and `.ipa` to the release.

   To retry one platform (for example after fixing a secret), run the workflow by hand from the Actions tab with the tag and the platform. If the fix is in the code, set `ref` to the branch that has it (its `pubspec.yaml` version must still match the tag). Each upload needs a new build number, so a retry after a successful store upload needs a version bump.
9. For Android, go to the [Google Play Console](https://play.google.com/console/u/0/developers/5997297823226279773/app/4974667565177679063/app-dashboard?timespan=thirtyDays) and promote the internal release to production.
10. For iOS, go to the [AppStoreConnect test flight section](https://appstoreconnect.apple.com/apps/6474765181/testflight/ios), accept the agreement if asked, then create the new App Store version with the uploaded build and submit it for review.
11. Now you can get your coffee and chill until they review the apps. It takes about 2 or 3 working days to review both of them.
12. When the app is published, you need to check the firebase crashlytics to make sure that there is no new crashes.

## Release workflow secrets

Add these under **Settings → Secrets and variables → Actions**. For files, store the base64 text (`base64 -i <file> | pbcopy` on macOS).

| Secret | Value |
|---|---|
| `FIREBASE_OPTIONS_DART_B64` | base64 of `lib/firebase_options.dart` |
| `GOOGLE_SERVICES_JSON_B64` | base64 of `android/app/google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST_B64` | base64 of `ios/Runner/GoogleService-Info.plist` |
| `FIREBASE_APP_ID_FILE_JSON_B64` | base64 of `ios/firebase_app_id_file.json` |
| `FIREBASE_JSON_B64` | base64 of `firebase.json` |
| `ANDROID_KEYSTORE_B64` | base64 of the upload keystore (`.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service account JSON key (plain text) |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API issuer ID |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | contents of the `AuthKey_XXXX.p8` file |
| `IOS_CERTIFICATE_PRIVATE_KEY` | RSA private key for the distribution certificate (`ssh-keygen -t rsa -b 2048 -m PEM -f ios_cert_key -q -N ""`) |
| `PORTAL_DEPLOY_KEY` | Private SSH key for the web build workflow (below). Its public half is a deploy key with write access on `app2pack-dev/app2pack_games`. Deploy keys don't expire. |

The Firebase files come from `make firebaseConfigs` on a machine that is logged in to Firebase. The build itself never logs in to Firebase.

## Web version on games.app2pack.dev

The `Web build to games portal` workflow (`.github/workflows/web-to-portal.yml`) runs on every push to `main` (changes to docs and Markdown files only are skipped), so the web version can be ahead of the stores. It builds the web version with `scripts/build-save-the-potato-web.sh` from the portal repo and pushes it to the `save-the-potato-web-update` branch of `app2pack-dev/app2pack_games`. The portal's own workflow opens a pull request that replaces `client/games/save-the-potato/` and merges it, and the server pulls the portal's `main` every 5 minutes, so it goes live at [games.app2pack.dev/play.html?game=save-the-potato](https://games.app2pack.dev/play.html?game=save-the-potato) by itself. To rebuild it by hand, for example from another branch, run the workflow from the Actions tab.

To set up the deploy key once:

1. Make a key pair: `ssh-keygen -t ed25519 -C save-the-potato-web-to-portal -N "" -f potato_portal_key`
2. In `app2pack_games`, Settings → Deploy keys → Add deploy key: paste `potato_portal_key.pub`, tick **Allow write access**.
3. In `save_the_potato`, Settings → Secrets and variables → Actions: add `PORTAL_DEPLOY_KEY` with the contents of `potato_portal_key` (the file without `.pub`). Then delete both files.
4. In `app2pack_games`, Settings → Actions → General: **Allow GitHub Actions to create and approve pull requests** must be ticked (it already is for Through The Galaxies).
