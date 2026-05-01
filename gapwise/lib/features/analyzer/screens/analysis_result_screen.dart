import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/analysis_result.dart';
import '../../../services/pdf_report_service.dart';

class AnalysisResultScreen extends ConsumerWidget {
  final AnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => PDFReportService.generateAndDownloadReport(result),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultHeader(atsScore: result.atsScore, keywordMatch: result.keywordMatchPercentage),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Resume Strength'),
            _StrengthCard(strength: result.resumeStrength),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Missing Skills'),
            _SkillsList(skills: result.missingSkills, color: GapWiseTheme.errorColor),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Weak Areas'),
            _SkillsList(skills: result.weakSkills, color: Colors.orange),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Experience Gap'),
            _TextCard(text: result.experienceGap),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Suggested Projects'),
            _ListCard(items: result.recommendedProjects, icon: Icons.rocket_outlined),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Improvement Suggestions'),
            _ListCard(items: result.improvementSuggestions, icon: Icons.tips_and_updates_outlined),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('New Analysis'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final int atsScore;
  final int keywordMatch;

  const _ResultHeader({required this.atsScore, required this.keywordMatch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeaderStat(label: 'ATS SCORE', value: '$atsScore%', color: GapWiseTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _HeaderStat(label: 'KEYWORD MATCH', value: '$keywordMatch%', color: GapWiseTheme.secondaryColor),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GapWiseTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GapWiseTheme.subtextColor)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _StrengthCard extends StatelessWidget {
  final String strength;
  const _StrengthCard({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GapWiseTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(strength, style: const TextStyle(height: 1.5)),
    );
  }
}

class _SkillsList extends StatelessWidget {
  final List<String> skills;
  final Color color;

  const _SkillsList({required this.skills, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => Chip(
        label: Text(skill, style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: color.withOpacity(0.2),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )).toList(),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String text;
  const _TextCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GapWiseTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(height: 1.5)),
    );
  }
}

class _ListCard extends StatelessWidget {
  final List<String> items;
  final IconData icon;

  const _ListCard({required this.items, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GapWiseTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: GapWiseTheme.secondaryColor),
              const SizedBox(width: 12),
              Expanded(child: Text(item, style: const TextStyle(height: 1.4))),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
