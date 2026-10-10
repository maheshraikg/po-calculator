import 'package:flutter/widgets.dart';

import '../data/local_rates.dart';
import '../data/saved_account_repository.dart';
import '../domain/rates/rate_repository.dart';
import 'settings.dart';
import 'strings.dart';

/// Gives every screen the settings, rate table and saved accounts.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.lang,
    required this.rates,
    required this.accounts,
    this.localRates,
    required super.child,
  });

  final AppSettings settings;

  /// Language when this scope was built: a change rebuilds every screen
  /// (the settings object itself stays the same).
  final Lang lang;
  final RateRepository rates;
  final SavedAccountRepository accounts;
  final LocalRates? localRates;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      settings != old.settings ||
      lang != old.lang ||
      rates != old.rates ||
      accounts != old.accounts ||
      localRates != old.localRates;
}

extension ScopeX on BuildContext {
  AppScope get scope => AppScope.of(this);
  AppSettings get settings => scope.settings;
  RateRepository get rates => scope.rates;
  SavedAccountRepository get accounts => scope.accounts;
  S get s => S(scope.settings.lang);
}
