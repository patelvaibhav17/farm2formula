class AnalysisResult {
  final List<String> missingSkills;
  final List<String> weakSkills;
  final String experienceGap;
  final int atsScore;
  final int keywordMatchPercentage;
  final List<String> improvementSuggestions;
  final List<String> recommendedProjects;
  final String resumeStrength;
  final String targetRole;

  AnalysisResult({
    required this.missingSkills,
    required this.weakSkills,
    required this.experienceGap,
    required this.atsScore,
    required this.keywordMatchPercentage,
    required this.improvementSuggestions,
    required this.recommendedProjects,
    required this.resumeStrength,
    required this.targetRole,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      missingSkills: List<String>.from(json['missing_skills'] ?? []),
      weakSkills: List<String>.from(json['weak_skills'] ?? []),
      experienceGap: json['experience_gap'] ?? '',
      atsScore: json['ats_score'] ?? 0,
      keywordMatchPercentage: json['keyword_match_percentage'] ?? 0,
      improvementSuggestions: List<String>.from(json['improvement_suggestions'] ?? []),
      recommendedProjects: List<String>.from(json['recommended_projects'] ?? []),
      resumeStrength: json['resume_strength'] ?? '',
      targetRole: json['target_role'] ?? 'Target Role',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'missing_skills': missingSkills,
      'weak_skills': weakSkills,
      'experience_gap': experienceGap,
      'ats_score': atsScore,
      'keyword_match_percentage': keywordMatchPercentage,
      'improvement_suggestions': improvementSuggestions,
      'recommended_projects': recommendedProjects,
      'resume_strength': resumeStrength,
      'target_role': targetRole,
    };
  }
}
