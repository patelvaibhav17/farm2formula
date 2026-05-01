import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../analyzer/providers/analysis_provider.dart';
import '../../../models/analysis_result.dart';

class ChatAssistantScreen extends ConsumerStatefulWidget {
  const ChatAssistantScreen({super.key});

  @override
  ConsumerState<ChatAssistantScreen> createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends ConsumerState<ChatAssistantScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'content': 'Hello! I am your GapWise AI Career Assistant. Ask me anything about your resume, career gaps, or how to land your target role!'}
  ];
  bool _isTyping = false;

  void _sendMessage() async {
    final query = _messageController.text;
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _messageController.clear();
      _isTyping = true;
    });

    final latestAnalysis = ref.read(latestAnalysisProvider).value;

    if (latestAnalysis == null) {
      setState(() {
        _messages.add({'role': 'ai', 'content': 'Please complete a resume analysis first so I can give you personalized advice based on your skills.'});
        _isTyping = false;
      });
      return;
    }

    final advice = await ref.read(aiServiceProvider).getCareerAdvice(query, latestAnalysis);

    setState(() {
      _messages.add({'role': 'ai', 'content': advice});
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Career Coach')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['role'] == 'ai';
                return _ChatBubble(message: msg['content']!, isAi: isAi);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('AI Coach is thinking...', style: TextStyle(color: GapWiseTheme.subtextColor, fontSize: 13)),
                  ],
                ),
              ),
            ),
          _ChatInput(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isAi;

  const _ChatBubble({required this.message, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAi ? GapWiseTheme.surfaceColor : GapWiseTheme.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 0 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 0),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          message,
          style: TextStyle(color: isAi ? GapWiseTheme.textColor : Colors.white, height: 1.4),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: GapWiseTheme.surfaceColor,
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ask anything about your career...',
                fillColor: GapWiseTheme.backgroundColor,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, color: GapWiseTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
