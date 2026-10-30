import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/widgets/rotating_controls.dart';

void main() {
  late List<String> calls;

  Future<void> pumpControls(WidgetTester tester) async {
    calls = [];
    await tester.pumpWidget(
      MaterialApp(
        home: RotationControls(
          showGuide: false,
          onLeftDown: () => calls.add('leftDown'),
          onLeftUp: () => calls.add('leftUp'),
          onRightDown: () => calls.add('rightDown'),
          onRightUp: () => calls.add('rightUp'),
        ),
      ),
    );
  }

  Offset leftSide(WidgetTester tester) {
    final size = tester.getSize(find.byType(RotationControls));
    return Offset(size.width * 0.25, size.height * 0.75);
  }

  Offset rightSide(WidgetTester tester) {
    final size = tester.getSize(find.byType(RotationControls));
    return Offset(size.width * 0.75, size.height * 0.75);
  }

  testWidgets('holding keeps rotating when the finger drifts', (tester) async {
    await pumpControls(tester);
    final gesture = await tester.startGesture(leftSide(tester));
    // Well past the tap slop, which used to cancel the hold.
    await gesture.moveBy(const Offset(40, -30));
    await tester.pump();
    expect(calls, ['leftDown']);
    await gesture.up();
    expect(calls, ['leftDown', 'leftUp']);
  });

  testWidgets('a side releases only when its last finger lifts', (
    tester,
  ) async {
    await pumpControls(tester);
    final first = await tester.startGesture(leftSide(tester), pointer: 1);
    final second = await tester.startGesture(
      leftSide(tester) + const Offset(10, 10),
      pointer: 2,
    );
    await first.up();
    expect(calls, ['leftDown']);
    await second.up();
    expect(calls, ['leftDown', 'leftUp']);
  });

  testWidgets('both sides work independently', (tester) async {
    await pumpControls(tester);
    final left = await tester.startGesture(leftSide(tester), pointer: 1);
    final right = await tester.startGesture(rightSide(tester), pointer: 2);
    await right.up();
    await left.cancel();
    expect(calls, ['leftDown', 'rightDown', 'rightUp', 'leftUp']);
  });
}
