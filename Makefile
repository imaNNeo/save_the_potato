analyze:
	flutter analyze

# Format only tracked files, so build/ and generated files such as
# lib/firebase_options.dart are skipped.
checkFormat:
	dart format -o none --set-exit-if-changed $$(git ls-files '*.dart')

checkstyle:
	make analyze && make checkFormat

format:
	dart format $$(git ls-files '*.dart')

runTests:
	flutter test

sure:
	make checkstyle && make runTests

firebaseConfigs:
	flutterfire configure -y  --project=save-the-potato --platforms=android,ios