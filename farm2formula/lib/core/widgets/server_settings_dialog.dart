import 'package:flutter/material.dart';
import '../network/api_config.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.serverIp);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns, color: Colors.green),
          SizedBox(width: 10),
          Text('Server Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the Laptop IP address (e.g. 172.20.10.3)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Laptop IP Address',
              border: OutlineInputBorder(),
              hintText: '172.20.x.x',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          const Text(
            'Note: App will restart to apply changes.',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newIp = _controller.text.trim();
            if (newIp.isNotEmpty) {
              await ApiConfig.updateServerIp(newIp);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server IP updated to $newIp. Please restart the app if connections fail.')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
