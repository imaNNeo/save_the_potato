## 1.4.0
* Add share functionality in the game-over page
* Add smooth tap and hold animation in the first page
* Add multi-spawn game mode (a series of orbs spawn at the same location)

## 1.3.1
* Pause background music when game goes into the background

## 1.3.0
* Added new audio and sound effects (switched from [flame_audio](https://pub.dev/packages/flame_audio) to [so_loud](https://pub.dev/packages/flutter_soloud) package)
* Improved explosion effect (particle) of the moving orbs
* Fixed bug in the share score function (capturing a screenshot)
* Removed all fastlane related files, we use CodeMagic now

## 1.2.3
* Minor animation effect on the shields

## 1.2.2
* Add wiredash analytics
* Fix generating infinite moving hearts

## 1.2.0
* Introduce heart/health concept instead of temperature bar (hot & cold). Now you have 3 hearts when the game starts, decreases when an orb hits you, there are some hearts coming towards you, you can collect them to increase your health. When you lose all hearts, the game is over.
* Don't show the rank in the trophy when it is larger than threshold
* Make the game a little bit harder
* Upgraded some dependencies

## 1.1.1
* Increase the difficulty of the game (specifically for the first minute)
* Show newRank celebration with a rank threshold (20 at the moment). Also show a newScore badge in gameOver UI

## 1.1.0
* Implement pagination in the leaderboard

## 1.0.3
* Fix infinite game bug
* Fix shimmer padding issue in the leaderboard
* Fix my_score tap feedback radius

## 1.0.2
* Fix missing libflutter.so issue
* Fix some typos in the game
* Add AD_ID permission in the android manifest (used by firebase_analytics)

## 1.0.1
* Add firebase analytics

## 1.0.0
* 🚀Initial Release!
* Use Cookies font for the trophy and shareable score image
* MaxWidth 300 for all dialogs
* Fix audio enabled crash
* Override remote rank with the local when score is the same
* Fix captcha_dialog int parse crash
* Add more icon in the my_score widget

## 0.31.0
* Use pushReplacement instead of push when moving from splash to home
* Add user.id into the firebase crashlytics
* Show captcha for suspicious devices
* Add a temporary code to migrate the old score value
* Update Fastfile to upload the ios symbols

## 0.30.0
* Ready for the release
* Disable android backup
* Remove subject from shared image
* Fix navigator pop issue

## 0.23.0
* Finalize share score functionality
* Update app name in Android
* Fix offline score issue
* Fix audio issues
* Reload leaderboard after a high-score
* Upload firebase symbols for iOS

## 0.22.0
* Implement share high-score functionality
* Implement celeberate high-score page
* Show rank in the trophy icon on the top left (with max 99 number)

## 0.21.0
* Add iOS minVersion 12.0

## 0.20.0
* Regenerate iOS, Android and macOS icons
* Disable captcha

## 0.18.0
* Show a captcha when app opens (before everything)

## 0.17.0
* Added Splash page to handle some initial checks, such as version check (force-update or normal-update)
* Smooth transition for pages and dialogs
* Error-handling in leaderboard

## 0.16.0
* Load maximum 20 items in leaderboard
* Implement shimmer effect in leaderboard page

## 0.15.0
* Add deviceId concept to keep track of user devices (later we will have push notif ID per device)

## 0.14.0
* Send userDeviceInfo to the back-end (on register function)
* Set 0 high-score when user opens the app app for the first time
* Show update nickname dialog after successfull login 

## 0.13.0
* Add Firebase crashlytics

## 0.12.0
* Finalized Authentication and leaderboard
* Allow to update nickname
* Show current score when game is paused

## 0.11.0
* Fixed leaderboard logic issues

## 0.10.0
* Implement leaderboard

## 0.9.0
* Implement authentication
* Add high-score (leaderboard) button on the top-left of the page

## 0.8.0
* Implement settings (to mute/unMute the audio)
* Implement pause/resume functionality
* Implement offline scoring (online scoring comes the next version)
* Add firebase core and anonymous sign-in (for online scoring in the next release)

## 0.7.0
* Improved touch behaviour
* Fixed shields issue when game starts

## 0.6.0
* Change debug panel's font to Roboto (for better readability)
* Re-implemented rotation controls using tap and buttons (instead of dragging)
* Re-implemented difficulty incrementing. Now it should be better

## 0.5.4
* Add publish to google play logic
* Fix google play package name in the workflow
* Change track to production
* Finalized CI/CD for Android and iOS

## 0.4.0
* Increase java version in CD workflows

## 0.3.0
* Fixed android/iOS CI issues

## 0.2.0
* Implemented CI/CD for Android (only build the app)
* Upload artifacts separately in each build

## 0.1.0
* Implemented CI/CD for iOS
* First version after [Flame Game Jam 3.0](https://itch.io/jam/flame-jam-3)
* Add release guide
