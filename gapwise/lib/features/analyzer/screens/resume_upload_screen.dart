import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../providers/analysis_provider.dart';
import 'analysis_result_screen.dart';

class ResumeUploadScreen extends ConsumerStatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  ConsumerState<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  PlatformFile? _pickedFile;
  final _jobDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jobDescriptionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  void _handleAnalysis() async {
    if (_pickedFile == null || _jobDescriptionController.text.isEmpty) return;

    final file = File(_pickedFile!.path!);
    
    // Start the analysis
    await ref.read(analysisProvider.notifier).startAnalysis(
          file,
          _jobDescriptionController.text,
        );

    // After analysis, check the state
    if (!mounted) return;
    final state = ref.read(analysisProvider);

    if (state.hasValue && state.value != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(result: state.value!),
        ),
      );
    } else if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${state.error}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final isAnalyzing = analysisState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('New Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step 1: Upload Resume', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Stack(
              children: [
                _UploadZone(
                  fileName: _pickedFile?.name,
                  onTap: isAnalyzing ? () {} : _pickFile,
                ),
                if (_pickedFile != null && !isAnalyzing)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _pickedFile = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Step 2: Job Description', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _jobDescriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Paste the job description here...',
                alignLabelWithHint: true,
              ),
              enabled: !isAnalyzing,
            ),
            const SizedBox(height: 32),
            if (isAnalyzing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: GapWiseTheme.primaryColor),
                    SizedBox(height: 16),
                    Text('AI is analyzing your resume...', style: TextStyle(color: GapWiseTheme.subtextColor)),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: (_pickedFile != null && _jobDescriptionController.text.isNotEmpty)
                    ? _handleAnalysis
                    : null,
                child: const Text('Start Analysis'),
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;

  const _UploadZone({this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: GapWiseTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: fileName != null ? GapWiseTheme.primaryColor : const Color(0xFF334155),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              fileName != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
              size: 48,
              color: fileName != null ? GapWiseTheme.secondaryColor : GapWiseTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              fileName ?? 'Upload PDF or DOCX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: fileName != null ? GapWiseTheme.textColor : GapWiseTheme.subtextColor,
              ),
            ),
            if (fileName == null)
              const Text('Max size: 5MB', style: TextStyle(fontSize: 12, color: GapWiseTheme.subtextColor)),
          ],
        ),
      ),
    );
  }
}
