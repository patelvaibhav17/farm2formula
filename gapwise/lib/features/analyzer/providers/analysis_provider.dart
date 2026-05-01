import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/analysis_result.dart';
import '../../../services/ai_service.dart';
import '../../../services/parser_service.dart';
import 'history_provider.dart';

final geminiApiKey = 'AIzaSyA1BdLRZzj2D1l4smnZbUDXe349JM0k1N8';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(geminiApiKey);
});

final latestAnalysisProvider = StreamProvider<AnalysisResult?>((ref) {
  final sessionAnalysis = ref.watch(analysisProvider).value;
  if (sessionAnalysis != null) return Stream.value(sessionAnalysis);

  // Fallback to history if no session analysis
  final history = ref.watch(historyProvider).value;
  if (history != null && history.isNotEmpty) return Stream.value(history.first);

  return Stream.value(null);
});

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AsyncValue<AnalysisResult?>>((ref) {
  return AnalysisNotifier(
    ref.read(aiServiceProvider),
    ref.read(historyRepositoryProvider),
  );
});

class AnalysisNotifier extends StateNotifier<AsyncValue<AnalysisResult?>> {
  final AIService _aiService;
  final HistoryRepository _historyRepository;

  AnalysisNotifier(this._aiService, this._historyRepository)
      : super(const AsyncValue.data(null));

  Future<void> startAnalysis(File file, String jobDescription) async {
    state = const AsyncValue.loading();
    try {
      print("🚀 Analysis Started...");
      if (!await file.exists()) throw Exception("File does not exist");
      if (jobDescription.trim().isEmpty) throw Exception("Job description is empty");

      print("📂 Step 1: Extracting text from file...");
      final text = await ParserService.extractText(file);
      if (text.trim().isEmpty) throw Exception("Could not extract text from file");
      print("✅ Text Extracted (${text.length} characters)");

      // Basic Resume Integrity Check
      if (!ParserService.isLikelyResume(text)) {
        throw Exception("This file does not appear to be a resume. Please upload a valid resume PDF or DOCX.");
      }
      print("🎯 Resume Validation Passed");

      print("🤖 Step 2: Sending to Gemini AI...");
      final result = await _aiService
          .analyzeResume(text, jobDescription)
          .timeout(const Duration(seconds: 45));
      print("✅ AI Analysis Complete");

      if (result != null) {
        print("💾 Step 3: Saving to Firestore...");
        await _historyRepository.saveAnalysis(result);
        print("✅ Data Saved to Firestore");
      }

      state = AsyncValue.data(result);
    } on TimeoutException {
      print("❌ Analysis Error: Timeout");
      state = AsyncValue.error("Request timed out. Try again.", StackTrace.current);
    } catch (e, st) {
      String errorMessage = e.toString();
      if (errorMessage.contains("PERMISSION_DENIED") || errorMessage.contains("API has not been used")) {
        errorMessage = "Cloud Firestore API is disabled or Security Rules are blocking access.";
      } else if (errorMessage.contains("API key not valid")) {
        errorMessage = "Invalid Gemini API Key. Please check your AI configuration in analysis_provider.dart.";
      } else if (errorMessage.contains("not found for API version v1beta")) {
        errorMessage = "Gemini Model Not Found: Ensure 'Generative Language API' is enabled in your Google Cloud Project or try a fresh key from aistudio.google.com.";
      } else if (errorMessage.contains("SAFETY") || errorMessage.contains("blocked")) {
        errorMessage = "The AI blocked the response due to safety filters. Try rephrasing your job description.";
      } else if (errorMessage.contains("429") || errorMessage.contains("Quota")) {
        errorMessage = "Gemini API Quota exceeded. Please wait a moment and try again.";
      }
      
      print("❌ Analysis Error: $errorMessage");
      print("Details: $e");
      state = AsyncValue.error(errorMessage, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}