import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/onTripPage/map_page/widgets/trip_selection_panel.dart';

Widget _wrap({
  required Size screenSize,
  required double keyboardHeight,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        padding: const EdgeInsets.only(top: 44),
      ),
      child: Scaffold(
        body: TripSelectionOverlay(
          rtl: true,
          pickupAddress: 'Test pickup address',
          pickupSearchController: TextEditingController(),
          destinationController: TextEditingController(),
          pickupEditing: false,
          destinationEditing: true,
          onBack: () {},
          onPickupTap: () {},
          onPickupChanged: (_) {},
          onClearPickup: () {},
          onDestinationTap: () {},
          onDestinationChanged: (_) {},
          onClearDestination: () {},
          onChooseFromMap: () {},
          onContinue: () {},
          canContinue: false,
          places: const [],
        ),
      ),
    ),
  );
}

void main() {
  // Regression test for the destination-picker keyboard-layout bug: the
  // panel used a fixed height while being repositioned above the keyboard,
  // so on smaller screens its top (and the pickup field inside it) was
  // pushed off the top of the screen once the keyboard opened.
  testWidgets(
      'panel top stays on-screen with keyboard open on a small iPhone',
      (tester) async {
    // iPhone SE-sized screen with a full-height keyboard.
    await tester.pumpWidget(
      _wrap(screenSize: const Size(375, 667), keyboardHeight: 291),
    );
    await tester.pumpAndSettle();

    final panelTop = tester.getTopLeft(find.byType(DecoratedBox).first).dy;
    expect(panelTop, greaterThanOrEqualTo(0),
        reason: 'The panel (and the pickup field inside it) must not be '
            'pushed above the top of the screen when the keyboard opens.');
  });

  testWidgets('panel top stays on-screen with keyboard open on a large iPhone',
      (tester) async {
    // iPhone Pro Max-sized screen.
    await tester.pumpWidget(
      _wrap(screenSize: const Size(430, 932), keyboardHeight: 336),
    );
    await tester.pumpAndSettle();

    final panelTop = tester.getTopLeft(find.byType(DecoratedBox).first).dy;
    expect(panelTop, greaterThanOrEqualTo(0));
  });

  testWidgets('panel keeps its normal larger height with keyboard closed',
      (tester) async {
    await tester.pumpWidget(
      _wrap(screenSize: const Size(390, 844), keyboardHeight: 0),
    );
    await tester.pumpAndSettle();

    final panelTop = tester.getTopLeft(find.byType(DecoratedBox).first).dy;
    expect(panelTop, greaterThanOrEqualTo(0));
    // With no keyboard, the panel should still comfortably clear the header.
    expect(panelTop, greaterThanOrEqualTo(60));
  });
}
