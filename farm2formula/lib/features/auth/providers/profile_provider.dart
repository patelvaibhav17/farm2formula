import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists the selected avatar seed for the current session.
/// In a real app, this would be saved to Firebase/Firestore.
final userAvatarProvider = StateProvider<String>((ref) => 'Felix');

/// Simple toggle for app theme (mock implementation for settings)
final darkThemeProvider = StateProvider<bool>((ref) => false);
