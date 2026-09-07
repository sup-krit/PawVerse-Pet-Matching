import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawverse_matching/main.dart';
import 'package:pawverse_matching/demo_repository.dart';

import 'domain_test.dart' show FailingRepository;

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('test-artifacts')..createSync(recursive: true);
    File('${directory.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    var directory = File(Platform.resolvedExecutable).parent;
    while (!Directory('${directory.path}/bin/cache/artifacts/material_fonts')
            .existsSync() &&
        directory.parent.path != directory.path) {
      directory = directory.parent;
    }
    final base = '${directory.path}/bin/cache/artifacts/material_fonts';
    final regular = File('$base/roboto-regular.ttf');
    if (regular.existsSync()) {
      final loader = FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(regular.readAsBytesSync())));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('$base/materialicons-regular.otf').readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
    }
  });
  testWidgets('mobile mutual match, text send and block close composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: PawVerseApp(
          repository: DemoMatchingRepository(delay: Duration.zero),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Discovering as Milo'), findsOneWidget);
    await capture(tester, key, 'discover-mobile');
    await tester.ensureVisible(find.byKey(const Key('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('like-button')));
    await tester.pumpAndSettle();
    expect(find.text('A new connection!'), findsOneWidget);
    await tester.tap(find.text('Go to matches'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poppy'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('message-input')),
      'Hello! Does Poppy enjoy gentle walks?',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Hello! Does Poppy enjoy gentle walks?'), findsOneWidget);
    await capture(tester, key, 'chat-mobile');
    await tester.tap(find.byTooltip('Conversation safety'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block owner'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Block owner'));
    await tester.pumpAndSettle();
    expect(
      find.text('Conversation closed. New messages are disabled.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('message-input')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('error retry and active pet switch have meaningful states', (
    tester,
  ) async {
    final fake = FailingRepository();
    await tester.pumpWidget(PawVerseApp(repository: fake));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    fake.gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    fake.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pet-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();
    expect(find.text('Discovering as Luna'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'narrow screen at large text can reach filters without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        PawVerseApp(repository: DemoMatchingRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Discovery filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cats'));
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.text('Mochi, 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
