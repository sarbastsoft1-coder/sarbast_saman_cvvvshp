import 'package:flutter_test/flutter_test.dart';

/// Pumps a bounded number of frames instead of `pumpAndSettle`.
///
/// The Roni app runs several ambient animations that never stop — the bottom
/// nav coin float and shimmer, the promo carousel's auto-advance timer, the
/// pulse on the flash-deals icon. `pumpAndSettle` waits for *all* scheduled
/// frames to finish, so it times out against any screen that shows the
/// navigation bar. A bounded pump settles the layout and the entrance
/// animations without waiting for ambient loops that will never end.
Future<void> settle(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 60),
  int frames = 12,
}) async {
  await tester.pump();
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}
