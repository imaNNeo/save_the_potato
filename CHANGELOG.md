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
