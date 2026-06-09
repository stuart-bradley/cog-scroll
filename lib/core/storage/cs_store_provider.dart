import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cs_store_provider.g.dart';

/// Provides the app-wide [CsStore].
///
/// Async because [SharedPreferences.getInstance] is async. M3 may switch to an
/// eager-synchronous store (resolved in `main()` and injected via a
/// `ProviderScope` override) if game engines need synchronous reads.
@Riverpod(keepAlive: true)
Future<CsStore> csStore(Ref ref) async =>
    CsStore(await SharedPreferences.getInstance());
