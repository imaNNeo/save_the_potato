analyze:
	flutter analyze

checkFormat:
	dart format -o none --set-exit-if-changed .

checkstyle:
	make analyze && make checkFormat

format:
	dart format .

runTests:
	flutter test

sure:
	make checkstyle && make runTests

firebaseConfigs:
	flutterfire configure -y  --project=save-the-potato --platforms=android,ios