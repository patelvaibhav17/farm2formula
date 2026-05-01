import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/analysis_result.dart';
import '../../auth/providers/auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final historyProvider = StreamProvider<List<AnalysisResult>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .collection('analyses')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
          .map((doc) => AnalysisResult.fromJson(doc.data()))
          .toList();
      })
      .handleError((error) {
        print("Firestore History Error: $error");
        return <AnalysisResult>[];
      });
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(firestoreProvider), ref.watch(firebaseAuthProvider));
});

class HistoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HistoryRepository(this._firestore, this._auth);

  Future<void> saveAnalysis(AnalysisResult result) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = result.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('analyses')
        .add(data);
  }
}
