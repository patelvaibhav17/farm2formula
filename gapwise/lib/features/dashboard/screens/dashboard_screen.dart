import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../core/theme.dart';
import '../../analyzer/screens/resume_upload_screen.dart';
import '../../chat/screens/chat_assistant_screen.dart';
import '../../analyzer/screens/resume_rewriter_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../analyzer/providers/analysis_provider.dart';
import '../../analyzer/screens/analysis_result_screen.dart';
import '../../../models/analysis_result.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAnalysis = ref.watch(latestAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GapWise Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            },
          ),
        ],
      ),

      body: latestAnalysis.when(
        data: (analysis) {
          if (analysis == null) {
            return const _EmptyDashboardState();
          }
          return _DashboardContent(analysis: analysis);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeUploadScreen()));
        },
        backgroundColor: GapWiseTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Analysis', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final AnalysisResult analysis;
  const _DashboardContent({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _UserProfileHeader(),
          const SizedBox(height: 32),
          _ATSScoreOverview(score: analysis.atsScore.toDouble()),
          const SizedBox(height: 32),
          const _QuickActionSection(),
          const SizedBox(height: 32),
          Text('Gap Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _GapSummaryCard(
            title: 'Missing Skills',
            subtitle: analysis.missingSkills.isEmpty 
              ? 'Excellent! No crucial skills missing.' 
              : '${analysis.missingSkills.length} key skills missing for ${analysis.targetRole}.',
            icon: Icons.error_outline,
            color: analysis.missingSkills.isEmpty ? GapWiseTheme.secondaryColor : GapWiseTheme.errorColor,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisResultScreen(result: analysis)));
            },
          ),
          const SizedBox(height: 12),
          _GapSummaryCard(
            title: 'Suggested Projects',
            subtitle: analysis.recommendedProjects.isEmpty
              ? 'Resume looks solid. Keep it updated!'
              : 'Boost your profile with ${analysis.recommendedProjects.length} expert projects.',
            icon: Icons.lightbulb_outline,
            color: GapWiseTheme.secondaryColor,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AnalysisResultScreen(result: analysis)));
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _UserProfileHeader(),
            const SizedBox(height: 48),
            Icon(Icons.description_outlined, size: 80, color: GapWiseTheme.subtextColor.withOpacity(0.3)),
            const SizedBox(height: 24),
            const Text(
              'No Analysis Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload your resume to see your ATS score and personalized career roadmap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GapWiseTheme.subtextColor),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeUploadScreen()));
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Analyze My Resume'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfileHeader extends ConsumerWidget {
  const _UserProfileHeader();

  void _showProfileSheet(BuildContext context, WidgetRef ref, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GapWiseTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: GapWiseTheme.subtextColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
              ),
              CircleAvatar(
                radius: 40,
                backgroundColor: GapWiseTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  (user.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: GapWiseTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? 'Standard User', 
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(user.email ?? '', style: const TextStyle(color: GapWiseTheme.subtextColor)),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Update Professional Name',
                  hintText: 'Enter your name...',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onSubmitted: (newName) async {
                  if (newName.isNotEmpty) {
                    await user.updateDisplayName(newName);
                    await user.reload(); // Force refresh local user instance
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully!')));
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _ProfileDetailTile(icon: Icons.badge_outlined, label: 'Account ID', value: user.uid.substring(0, 8) + '...'),
              _ProfileDetailTile(icon: Icons.calendar_today_outlined, label: 'Member Since', value: 'Recent User'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GapWiseTheme.errorColor.withOpacity(0.1), 
                    foregroundColor: GapWiseTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox();
    final name = user.displayName ?? user.email?.split('@').first ?? 'User';

    return InkWell(
      onTap: () => _showProfileSheet(context, ref, user),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: GapWiseTheme.primaryColor,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: TextStyle(color: GapWiseTheme.subtextColor, fontSize: 13)),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GapWiseTheme.textColor)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: GapWiseTheme.subtextColor),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: GapWiseTheme.subtextColor),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: GapWiseTheme.subtextColor)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ATSScoreOverview extends StatelessWidget {
  final double score;
  const _ATSScoreOverview({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GapWiseTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  startAngle: 270,
                  endAngle: 270,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.15,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Color(0xFF334155),
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: score,
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      cornerStyle: CornerStyle.bothCurve,
                      gradient: const SweepGradient(
                        colors: <Color>[GapWiseTheme.primaryColor, GapWiseTheme.secondaryColor],
                        stops: <double>[0.25, 0.75],
                      ),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      positionFactor: 0.1,
                      angle: 90,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.toInt().toString(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: GapWiseTheme.textColor),
                          ),
                          const Text('ATS', style: TextStyle(fontSize: 12, color: GapWiseTheme.subtextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Great Job!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Your resume is stronger than 85% of applicants for this role.', style: TextStyle(color: GapWiseTheme.subtextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionSection extends StatelessWidget {
  const _QuickActionSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Resume Rewriter',
            icon: Icons.edit_note_outlined,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeRewriterScreen()));
            },
          ),

        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            title: 'AI Careers Chat',
            icon: Icons.chat_bubble_outline,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatAssistantScreen()));
            },
          ),
        ),
      ],
    );
  }
}


class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: GapWiseTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: GapWiseTheme.primaryColor, size: 32),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GapSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GapSummaryCard({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GapWiseTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: GapWiseTheme.subtextColor, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: GapWiseTheme.subtextColor),
          ],
        ),
      ),
    );
  }
}
