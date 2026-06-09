import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cs_store_provider.g.dart';

/// Provides the app-wide [CsStore], resolved **synchronously**.
///
/// `SharedPreferences` is loaded once in `main()` and the resulting [CsStore]
/// is installed via a `ProviderScope` override, so game engines can read
/// state synchronously on `start()`. The default implementation throws, turning
/// a missing override into a loud boot error rather than a silent failure.
///
/// Tests that pump the app override it with a [CsStore] over
/// `SharedPreferences.setMockInitialValues({})`; pure-engine tests use a fake
/// `GameStore` instead.
@Riverpod(keepAlive: true)
CsStore csStore(Ref ref) => throw UnimplementedError(
  'csStoreProvider must be overridden in ProviderScope (resolved in main()).',
);
