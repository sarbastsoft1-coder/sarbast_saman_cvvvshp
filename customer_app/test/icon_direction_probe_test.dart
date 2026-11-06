import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the candidate directional icons inside an RTL context and writes a
/// PNG, so the arrow directions can be confirmed from pixels rather than
/// inferred from the SDK's `matchTextDirection` flag.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('icon direction probe', (tester) async {
    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    const icons = <(String, IconData)>[
      ('chevron_left', Icons.chevron_left_rounded),
      ('chevron_right', Icons.chevron_right_rounded),
      ('arrow_forward', Icons.arrow_forward_rounded),
      ('arrow_back', Icons.arrow_back_rounded),
      ('arrow_back_ios', Icons.arrow_back_ios_rounded),
      ('navigate_next', Icons.navigate_next_rounded),
      ('navigate_before', Icons.navigate_before_rounded),
      ('west', Icons.west_rounded),
      ('east', Icons.east_rounded),
    ];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (name, icon) in icons)
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Icon(icon, size: 40, color: Colors.black),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build').create(recursive: true);
      await File(
        'build/icon-probe.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  });
}
