import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../providers/analysis_provider.dart';
import '../../../models/analysis_result.dart';

class ResumeRewriterScreen extends ConsumerStatefulWidget {
  const ResumeRewriterScreen({super.key});

  @override
  ConsumerState<ResumeRewriterScreen> createState() => _ResumeRewriterScreenState();
}

class _ResumeRewriterScreenState extends ConsumerState<ResumeRewriterScreen> {
  final _bulletController = TextEditingController();
  final _roleController = TextEditingController();
  String _rewrittenBullet = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill role from latest analysis if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final latest = ref.read(latestAnalysisProvider).value;
      if (latest != null && _roleController.text.isEmpty) {
        _roleController.text = latest.targetRole;
      }
    });
  }

  void _rewrite() async {
    if (_bulletController.text.isEmpty || _roleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both the role and a bullet point.'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _rewrittenBullet = '';
    });
    
    try {
      final rewritten = await ref.read(aiServiceProvider).rewriteResumeBullet(
        _bulletController.text,
        _roleController.text,
      );

      setState(() {
        _rewrittenBullet = rewritten;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rewrite: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Resume Rewriter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transform your bullet points into high-impact statements.', style: TextStyle(color: GapWiseTheme.subtextColor)),
            const SizedBox(height: 32),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Target Job Role',
                hintText: 'e.g. Senior Software Engineer',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bulletController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Current Bullet Point',
                hintText: 'e.g. Responsible for developing web apps using React.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _rewrite,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Text('Rewrite with AI'),
            ),
            const SizedBox(height: 48),
            if (_rewrittenBullet.isNotEmpty) ...[
              const Text('AI Suggestion:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: GapWiseTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GapWiseTheme.secondaryColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(_rewrittenBullet, style: const TextStyle(fontSize: 16, height: 1.5, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _rewrittenBullet));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy to Clipboard'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
