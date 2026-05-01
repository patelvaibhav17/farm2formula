import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple stream provider that emits a value every 10 seconds.
/// Dashboards listen to this to 'auto-pull' fresh data from the blockchain.
final syncProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (i) => i);
});
