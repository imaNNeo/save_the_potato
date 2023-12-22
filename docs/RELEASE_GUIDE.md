Steps to release a version:

1. Create a new branch with this pattern: `release/x.y.z`
2. Update the version name and version code in the pubspec.yaml
3. Replace `newVersion` with the version that you decided in the CHANGELOG.md
4. Update the `assets/texts/release_notes.json` file to put the release notes
5. Commit and push the changes with a message like this: `Bump version to x.y.z`
6. Go to the repository [releases section](https://github.com/imaNNeo/save_the_potato/releases) and create a new release. Create a tag for it with this pattern: `x.y.z` and **choose the branch that you created in the first step as the Target branch**.
7. Copy and paste the latest changelog from [CHANGELOG.md](https://github.com/imaNNeo/save_the_potato/blob/master/CHANGELOG.md) file into the description field.
8. Then publish the release. It triggers the [release workflow](https://github.com/imaNNeo/save_the_potato/blob/master/.github/workflows/release.yml) to build and publish the iOS and Android apps. It also attaches the artifacts(apk, aab and ipa) to the release that you have created.
9. For Android, you need to go to the [Google Play Console](https://play.google.com/console/u/0/developers/5997297823226279773/app/4974667565177679063/app-dashboard?timespan=thirtyDays) and create a new release using the .aab file that produced in the previous step (attached in the [latest release](https://github.com/imaNNeo/save_the_potato/releases/latest)). Also you need to write a release note (use what you write in the `release_notes.json` file)
10. For iOS, you need to go to the [AppStoreConnect test flight section](https://appstoreconnect.apple.com/apps/6474765181/testflight/ios) and accept the agreement. Then you can release a new version.
11. Now you can get your coffee and chill until they review the apps. It takes about 2 or 3 working days to review both of them.
12. When the app is published, you need to check the firebase crashlytics to make sure that there is no new crashes.