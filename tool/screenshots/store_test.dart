// Play Store phone screenshots (1080x1920, at most 8) from the current app.
//
//   FLUTTER_ROOT=<sdk> flutter test tool/screenshots/store_test.dart
//   (TABLET=1 renders tablet-size screens into store/screenshots/raw_tablet/)
//
// Needs Roboto (Flutter SDK cache) and Noto Sans for the Indian scripts
// (apt install fonts-noto-core). Output: store/screenshots/raw/*.png (then python3 tool/make_store_screenshots.py)
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:ui' as ui;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/app/settings.dart';
import 'package:po_sahayak/app/theme.dart';
import 'package:po_sahayak/data/saved_account_repository.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:po_sahayak/domain/rates/rate_repository.dart';
import 'package:po_sahayak/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/features/result/result_screen.dart';

Future<void> loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final mf = '$sdk/bin/cache/artifacts/material_fonts';
  const noto = '/usr/share/fonts/truetype/noto';
  final tablet = Platform.environment['TABLET'] == '1';
  final out = tablet ? 'store/screenshots/raw_tablet' : 'store/screenshots/raw';
  const scripts = [
    'Kannada',
    'Devanagari',
    'Bengali',
    'Telugu',
    'Tamil',
    'Gujarati',
    'Malayalam',
    'Oriya',
    'Gurmukhi',
  ];

  setUpAll(() async {
    await loadFont('Roboto', [
      '$mf/Roboto-Regular.ttf',
      '$mf/Roboto-Medium.ttf',
      '$mf/Roboto-Bold.ttf',
      '$mf/Roboto-Black.ttf',
    ]);
    await loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    for (final sc in scripts) {
      await loadFont('Noto$sc', [
        '$noto/NotoSans$sc-Regular.ttf',
        '$noto/NotoSans$sc-Bold.ttf',
      ]);
    }
    debugFontFallback = [for (final sc in scripts) 'Noto$sc'];
    Directory(out).createSync(recursive: true);
  });

  testWidgets('store screenshots', (tester) async {
    await tester.binding.setSurfaceSize(
      tablet ? const Size(800, 1280) : const Size(540, 960),
    );
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    final settings = await AppSettings.load();
    final accounts = await SavedAccountRepository.load();
    final rates = RateRepository.fromJson(
      File('assets/rates.json').readAsStringSync(),
    );
    final today = DateUtils.dateOnly(DateTime.now());
    await accounts.add(
      'Amma SCSS',
      CalcInput(
        scheme: Scheme.scss,
        amount: Decimal.fromInt(1500000),
        opening: DateTime(today.year - 3, 6, 1),
        rate: Decimal.parse('8.2'),
      ),
    );
    await accounts.add(
      'Ravi RD',
      CalcInput(
        scheme: Scheme.rd,
        amount: Decimal.fromInt(5000),
        opening: DateTime(today.year - 2, 2, 10),
        rate: Decimal.parse('6.7'),
      ),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: PoSahayakApp(
          settings: settings,
          rates: rates,
          accounts: accounts,
          background: false,
        ),
      ),
    );

    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    Future<void> shot(String name) async {
      await settle();
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    Finder list() => find.byType(Scrollable).last;
    // Brings [text] near the top of the page (a drag could tap a card).
    Future<void> scrollTo(String text, {double at = 0.03}) async {
      await tester.scrollUntilVisible(
        find.text(text).last,
        200,
        scrollable: list(),
      );
      await settle();
      await tester.runAsync(() async {});
      Scrollable.ensureVisible(
        tester.element(find.text(text).last),
        alignment: at,
      );
      await settle();
    }

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    CalcResult calc(Scheme s, int amount, String rate) => calculate(
      CalcInput(
        scheme: s,
        amount: Decimal.fromInt(amount),
        opening: today,
        rate: Decimal.parse(rate),
      ),
    );

    await shot('1_home');

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.td5, 500000, '7.5')),
      ),
    );
    await shot('2_result');
    nav.pop();
    await settle();

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.mis, 500000, '7.4')),
      ),
    );
    await settle();
    await scrollTo('Suggestions');
    await shot('3_suggestions');
    nav.pop();
    await settle();

    await tester.tap(find.byIcon(Icons.leaderboard_outlined).last);
    await shot('4_compare');

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined).last);
    await shot('5_accounts');

    await tester.tap(find.byIcon(Icons.support_agent_outlined).last);
    await settle();
    await scrollTo('RD advance deposit rebate');
    await shot('6_rd_rebate');
    await scrollTo('Official forms');
    await shot('7_forms');

    await tester.tap(find.byIcon(Icons.home_outlined).last);
    await settle();
    await tester.tap(find.text('English').first);
    await shot('8_languages');
  });
}
