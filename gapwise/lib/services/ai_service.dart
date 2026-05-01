import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/analysis_result.dart';

class AIService {
  final String _apiKey;
  late final GenerativeModel _model;

  AIService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
    );
  }

  /// Helper to try different model names if one fails
  GenerativeModel _getModel(String modelName) {
    return GenerativeModel(model: modelName, apiKey: _apiKey);
  }

  Future<AnalysisResult> analyzeResume(String resumeText, String jobDescription) async {
    final prompt = """
Analyze the following resume against the given job description.

Resume:
$resumeText

Job Description:
$jobDescription

Provide output in JSON format with:

1. missing_skills (list)
2. weak_skills (list)
3. experience_gap (text explanation)
4. ats_score (0-100)
5. keyword_match_percentage (0-100)
6. improvement_suggestions (list)
7. recommended_projects (list)
8. resume_strength (short summary)
9. target_role (the specific job title extracted from the description)

Be strict and realistic. Do not give generic advice.
""";

    final modelsToTry = [
      'gemini-2.5-flash', 
      'gemini-3.1-flash-live-preview',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
    ];
    Map<String, String> errors = {};

    for (var modelName in modelsToTry) {
      try {
        print("🤖 [AI-Service] Attempting model: $modelName...");
        final model = _getModel(modelName);
        
        print("🤖 [AI-Service] Sending prompt (Length: ${prompt.length})...");
        final response = await model.generateContent([
          Content.text(prompt)
        ]).timeout(const Duration(seconds: 40));
        
        print("🤖 [AI-Service] Response received. Model: $modelName.");
        final text = response.text;
        
        if (text == null) throw Exception('Empty response from AI');
        
        // Extract JSON from potential markdown blocks
        String jsonString = text;
        if (text.contains('```')) {
          final jsonMatch = RegExp(r"```(?:json)?([\s\S]*?)```").firstMatch(text);
          jsonString = jsonMatch?.group(1)?.trim() ?? text;
        } else {
          final potentialJson = RegExp(r"\{[\s\S]*\}").firstMatch(text);
          jsonString = potentialJson?.group(0) ?? text;
        }
        
        final Map<String, dynamic> data = jsonDecode(jsonString);
        return AnalysisResult.fromJson(data);
      } catch (e) {
        errors[modelName] = e.toString();
        print("⚠️ Model $modelName failed: $e");
        continue; // Try next model
      }
    }

    // If all failed, provide a comprehensive error message
    String detailedError = errors.entries.map((e) => "${e.key}: ${e.value}").join("\n");
    throw Exception('AI Analysis failed after trying all models.\n\n$detailedError\n\nTIP: Please ensure "Generative Language API" is enabled in your Google Cloud Console or try a new key from aistudio.google.com');
  }

  Future<String> getCareerAdvice(String query, AnalysisResult lastAnalysis) async {
    final prompt = """
The user asked: "$query"
Based on their latest resume analysis:
ATS Score: ${lastAnalysis.atsScore}
Missing Skills: ${lastAnalysis.missingSkills.join(', ')}
Resume Strength: ${lastAnalysis.resumeStrength}

Provide specific, actionable advice to help them improve their resume or career prospects.
""";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "I'm sorry, I couldn't generate advice at this time.";
    } catch (e) {
      return "Something went wrong while chatting with AI: $e";
    }
  }

  Future<String> rewriteResumeBullet(String bulletPoint, String targetRole) async {
    final prompt = """
Rewrite the following resume bullet point to be more impact-oriented and better aligned with the role of $targetRole.
Original: "$bulletPoint"
Use the STAR method (Situation, Task, Action, Result) if possible. Keep it concise.
""";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? bulletPoint;
    } catch (e) {
      return bulletPoint;
    }
  }
}
