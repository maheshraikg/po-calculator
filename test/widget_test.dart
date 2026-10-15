import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/app/scope.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/features/accounts/accounts_screen.dart';
import 'package:po_sahayak/app/settings.dart';
import 'package:po_sahayak/app/strings.dart';
import 'package:po_sahayak/data/saved_account_repository.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:decimal/decimal.dart';
import 'package:po_sahayak/features/calculator/calculator_screen.dart';
import 'package:po_sahayak/features/compare/compare_screen.dart';
import 'package:po_sahayak/features/result/print_screen.dart';
import 'package:po_sahayak/features/result/result_screen.dart';
import 'package:po_sahayak/features/schemes/scheme_details_screen.dart';
import 'package:po_sahayak/features/settings/feedback_card.dart';
import 'package:po_sahayak/features/settings/settings_screen.dart';
import 'package:po_sahayak/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/helpers.dart';

Future<void> pumpApp(WidgetTester tester, {String lang = 'en'}) async {
  SharedPreferences.setMockInitialValues({'lang': lang});
  final settings = await AppSettings.load();
  final accounts = await SavedAccountRepository.load();
  await tester.pumpWidget(
    PoSahayakApp(
      settings: settings,
      rates: loadRates(),
      accounts: accounts,
      background: false,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows scheme tiles and switches language', (tester) async {
    await pumpApp(tester);
    expect(find.text('Deposits', skipOffstage: false), findsOneWidget);
    expect(find.text('Highest rate now'), findsOneWidget);
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ಕನ್ನಡ'));
    await tester.pumpAndSettle();
    expect(find.text('ಠೇವಣಿಗಳು', skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('TD5'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('TD5'), findsOneWidget);
  });

  testWidgets('TD5 calculation, save and My accounts', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(
      find.text('TD5'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('TD5'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '100000');
    await tester.ensureVisible(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.textContaining('₹7,714'), findsWidgets);
    expect(find.text('₹1,38,570'), findsWidgets);

    await tester.ensureVisible(find.text('Save account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Amma TD');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((r) => r.isFirst);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts').last);
    await tester.pumpAndSettle();
    expect(find.text('Amma TD'), findsWidgets);
  });

  testWidgets('every tab opens in Kannada', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, lang: 'kn');
    for (final label in ['ಹೋಲಿಕೆ', 'ಖಾತೆಗಳು', 'ಸಿಬ್ಬಂದಿ', 'ಸೆಟ್ಟಿಂಗ್ಸ್']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('result screen of every scheme fits a small phone in Kannada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, lang: 'kn');
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    for (final scheme in Scheme.values) {
      final r = calc(
        scheme,
        scheme.amountKind == AmountKind.monthly ? 5000 : 150000,
        '7.5',
        opening: DateTime(2024, 3, 1),
      );
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(result: r, girlAge: 5),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
      await tester.pumpAndSettle();
      final err = tester.takeException();
      expect(err, isNull, reason: scheme.code);
      nav.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('large phone font: home and every tab lay out without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final lang in ['en', 'kn']) {
      await pumpApp(tester, lang: lang);
      expect(tester.takeException(), isNull, reason: '$lang home');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$lang home scrolled');
      for (final icon in [
        Icons.leaderboard_outlined,
        Icons.account_balance_wallet_outlined,
        Icons.support_agent_outlined,
        Icons.settings_outlined,
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$lang $icon');
      }
    }
  });

  testWidgets('share sends the card image and the text', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.mssc, 1000, '7.5')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.share_rounded));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Share'));
      for (var i = 0; i < 50 && calls.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    final args = calls.single.arguments as Map;
    expect(args['text'], contains('₹1,160'));
    final path = (args['paths'] as List).single as String;
    expect(File(path).lengthSync(), greaterThan(1000));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('settings shares the download link', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    // Tall screen so the whole Settings page fits above the tab bar.
    tester.view.physicalSize = const Size(400 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share this app'));
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(
      (calls.single.arguments as Map)['text'],
      contains('po-calculator/releases/latest/download/po_calculator.apk'),
    );
  });

  testWidgets('staff tab shows the account opening steps', (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final lang in ['en', 'kn']) {
      await pumpApp(tester, lang: lang);
      await tester.tap(find.text(lang == 'en' ? 'Staff' : 'ಸಿಬ್ಬಂದಿ').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: lang);
      expect(
        find.text(
          lang == 'en' ? 'How to open the account' : 'ಖಾತೆ ತೆರೆಯುವ ವಿಧಾನ',
        ),
        findsOneWidget,
      );
    }
    expect(find.textContaining('Only the 5-year TD'), findsNothing);
    await pumpApp(tester);
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();
    expect(find.text('Official forms'), findsOneWidget);
    expect(find.text('Account Opening Form'), findsOneWidget);
    expect(find.text('KYC form (SB-KYC)'), findsOneWidget);
  });

  testWidgets('scheme details open from Staff and share the text', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full scheme details'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Who can open'), findsOneWidget);
    await tester.tap(find.text('Share details with customer'));
    await tester.pumpAndSettle();
    final text = (calls.single.arguments as Map)['text'] as String;
    expect(text, contains('Time Deposit 5 years (TD5)'));
    expect(text, contains('Early closure:'));
    expect(text, contains('Documents needed:'));
  });

  testWidgets('details page of every scheme lays out in Kannada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, lang: 'kn');
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    for (final scheme in Scheme.values) {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => SchemeDetailsScreen(scheme: scheme),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scheme.code);
      nav.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('every language: all tabs, a result and scheme details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final lang in Lang.values) {
      await pumpApp(tester, lang: lang.name);
      final s = S(lang);
      expect(find.text(s.appTitle), findsWidgets, reason: lang.name);
      for (final icon in [
        Icons.leaderboard_outlined,
        Icons.account_balance_wallet_outlined,
        Icons.support_agent_outlined,
        Icons.settings_outlined,
        Icons.home_outlined,
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${lang.name} $icon');
      }
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ResultScreen(result: calc(Scheme.scss, 500000, '8.2')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${lang.name} result');
      nav.pop();
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const SchemeDetailsScreen(scheme: Scheme.ppf),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${lang.name} details');
      nav.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('new install opens in English; tab labels follow the language', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    expect(settings.lang, Lang.en);
    await tester.pumpWidget(
      PoSahayakApp(
        settings: settings,
        rates: loadRates(),
        accounts: await SavedAccountRepository.load(),
        background: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Staff'), findsOneWidget);
    settings.lang = Lang.kn;
    await tester.pumpAndSettle();
    expect(find.text('ಸಿಬ್ಬಂದಿ'), findsOneWidget);
    expect(find.text('Staff'), findsNothing);
  });

  testWidgets('a form can be sent to a customer', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    tester.view.physicalSize = const Size(400 * 3, 3200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Download'), findsNWidgets(16));
    await tester.tap(find.byTooltip('Send to customer').first);
    await tester.pumpAndSettle();
    final text = (calls.single.arguments as Map)['text'] as String;
    expect(text, contains('Account Opening Form'));
    expect(text, contains('https://www.indiapost.gov.in/'));
  });

  test('feedback e-mail goes to the developer with the app version', () {
    final u = feedbackUri(
      subject: 'PO Calculator – bug report',
      body: 'Tax table wrong',
      lang: 'hi',
    );
    expect(u.scheme, 'mailto');
    expect(u.path, 'maheshraikg@gmail.com');
    final q = Uri.decodeComponent(u.query);
    expect(q, contains('subject=PO Calculator – bug report'));
    expect(q, contains('Tax table wrong'));
    expect(q, contains('PO Calculator $kAppVersion · hi'));
  });

  testWidgets('settings shows the developer and feedback buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Mahesh Rai'), findsOneWidget);
    expect(find.text('maheshraikg@gmail.com'), findsOneWidget);
    expect(find.text('Send a suggestion'), findsOneWidget);
    expect(find.text('Report a bug'), findsOneWidget);
  });

  testWidgets('MIS year-wise table shows interest paid out and fits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.mis, 10000, '7.4')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Paid so far'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Interest paid'), findsWidgets);
    expect(find.textContaining('deposit stays ₹10,000'), findsOneWidget);
    // ₹62 a month: ₹744 a year, adding up in "Paid so far".
    expect(find.text('₹1,488'), findsOneWidget);
    expect(find.text('₹3,720'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculator shows all scheme facts and opens full details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const CalculatorScreen(scheme: Scheme.mis),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.text('Documents needed & share with customer');
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('About Monthly Income Scheme'), findsOneWidget);
    expect(find.byType(SchemeInfoCard), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(SchemeDetailsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('compare covers every open scheme in three groups', () {
    final groups = compareAll(
      Decimal.fromInt(100000),
      DateTime(2026, 10, 10),
      (_) => Decimal.parse('7'),
    );
    expect(groups.map((g) => g.$1), CompareGroup.values);
    final shown = {for (final (_, rs) in groups) ...rs.map((r) => r.scheme)};
    expect(shown, Scheme.openable.toSet());
    // Over ₹1.5 lakh, PPF and SSY take the yearly limit.
    final big = compareAll(
      Decimal.fromInt(500000),
      DateTime(2026, 10, 10),
      (_) => Decimal.parse('7'),
    ).last.$2;
    expect(
      big.map((r) => r.input.amount),
      everyElement(Decimal.fromInt(150000)),
    );
  });

  testWidgets('joint account switch shows where joint accounts are allowed', (
    tester,
  ) async {
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    for (final scheme in Scheme.values) {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => CalculatorScreen(scheme: scheme),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(SwitchListTile),
        scheme.jointAllowed ? findsOneWidget : findsNothing,
        reason: scheme.code,
      );
      nav.pop();
      await tester.pumpAndSettle();
    }
    expect(Scheme.values.where((s) => !s.jointAllowed), [
      Scheme.ppf,
      Scheme.ssy,
      Scheme.mssc,
    ]);
  });

  testWidgets('staff tab: RD rebate calculator and service charges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Pay now'),
      300,
      scrollable: list,
    );
    await tester.pumpAndSettle();
    // ₹1,000 × 12 = ₹12,000, rebate ₹400.
    expect(find.text('₹12,000'), findsOneWidget);
    expect(find.text('− ₹400'), findsOneWidget);
    expect(find.text('₹11,600'), findsOneWidget);
    final six = find.widgetWithText(ChoiceChip, '6');
    await tester.ensureVisible(six);
    await tester.pumpAndSettle();
    await tester.tap(six);
    await tester.pumpAndSettle();
    expect(find.text('₹5,900'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cheque dishonour'),
      300,
      scrollable: list,
    );
    expect(find.text('Service charges'), findsOneWidget);
    expect(find.text('then ₹2 a leaf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MIS result suggests putting the interest into an RD', (
    tester,
  ) async {
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.mis, 100000, '7.4')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Suggestions'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('Put ₹610 a month of this interest into an RD'),
      findsOneWidget,
    );
    // NSC for everyone, SCSS for age 60+.
    expect(find.textContaining('Better return: '), findsNWidgets(2));
    expect(find.text('Age 60+ only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compare: "I want ₹" shows the deposit needed', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Compare').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('I want ₹'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '500000');
    await tester.pumpAndSettle();
    expect(find.text('How much to deposit to get this amount'), findsOneWidget);
    expect(find.text('Deposit once'), findsOneWidget);
    // KVP doubles the money.
    await tester.scrollUntilVisible(
      find.text('Kisan Vikas Patra'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Kisan Vikas Patra'),
          matching: find.byType(Card),
        ),
        matching: find.text('₹2,50,000'),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Save every year'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SCSS ₹15 lakh: Form 121 TDS reminder', (tester) async {
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.scss, 1500000, '8.2')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('TDS reminder'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.textContaining('above the ₹1,00,000 TDS limit'),
      findsOneWidget,
    );
    expect(find.text('Form 121'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no TDS reminder for a small TD', (tester) async {
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.td5, 100000, '7.5')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TDS reminder', skipOffstage: false), findsNothing);
  });

  testWidgets('customer printout shows the page and the PDF button', (
    tester,
  ) async {
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.ssy, 50000, '8.2')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer printout'));
    await tester.pumpAndSettle();
    expect(find.byType(PrintPage), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);
    // 21 years, one row each, plus the header.
    expect(find.text('21'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('PDF is one A4 page', () async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );
    final pdf = await pagePdf(png);
    final text = latin1.decode(pdf);
    expect(text.startsWith('%PDF'), isTrue);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 1);
    expect(text, contains('595'));
  });

  testWidgets('custom interest calculator and account filters', (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Custom interest calculator'),
      300,
      scrollable: list,
    );
    final simple = find.widgetWithText(ChoiceChip, 'Simple');
    await tester.scrollUntilVisible(simple, 200, scrollable: list);
    await tester.pumpAndSettle();
    await tester.tap(simple);
    await tester.pumpAndSettle();
    // ₹1,00,000 at 7% simple for 5 years: ₹35,000.
    expect(find.text('₹35,000'), findsOneWidget);
    expect(find.text('₹1,35,000'), findsOneWidget);

    await tester.tap(find.text('Accounts').last);
    await tester.pumpAndSettle();
    final repo = tester.element(find.byType(AccountsScreen)).accounts;
    final today = DateUtils.dateOnly(DateTime.now());
    await tester.runAsync(() async {
      // Matures in about 10 days, and one matured last year.
      await repo.add(
        'Soon',
        CalcInput(
          scheme: Scheme.td1,
          amount: Decimal.fromInt(10000),
          opening: DateTime(today.year - 1, today.month, today.day + 10),
          rate: Decimal.parse('6.9'),
        ),
      );
      await repo.add(
        'Old',
        CalcInput(
          scheme: Scheme.td1,
          amount: Decimal.fromInt(10000),
          opening: DateTime(today.year - 3, today.month, today.day),
          rate: Decimal.parse('6.9'),
        ),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('Next 3 months (1)'), findsOneWidget);
    expect(find.text('Matured (1)'), findsOneWidget);
    await tester.tap(find.text('Matured (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);
    expect(find.text('Soon'), findsNothing);
    expect(find.textContaining('Maturing this month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('official sources and disclaimer on home and settings', (
    tester,
  ) async {
    await pumpApp(tester);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Official sources'),
      300,
      scrollable: list,
    );
    expect(find.textContaining('It is not a government app'), findsWidgets);
    expect(find.text('www.nsiindia.gov.in', skipOffstage: false), findsWidgets);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Official sources', skipOffstage: false), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shows calculators and tools that open', (tester) async {
    await pumpApp(tester);
    expect(find.text('Calculators & tools'), findsOneWidget);
    await tester.tap(find.text('RD advance deposit rebate').first);
    await tester.pumpAndSettle();
    expect(find.text('Pay now'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom interest calculator').first);
    await tester.pumpAndSettle();
    expect(find.text('Total amount'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
