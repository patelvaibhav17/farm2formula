import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

// --- SHARED UI COMPONENTS ---
class SettingsHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const SettingsHeader({super.key, required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- PERSONAL INFO SCREEN ---
class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final avatarSeed = ref.watch(userAvatarProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.green.shade800, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: authState.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          final email = user.email ?? 'Unknown';
          
          return Column(
            children: [
              const SettingsHeader(title: 'Personal Info', icon: Icons.badge, color: Color(0xFF2E7D32)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                            child: Hero(
                              tag: 'profile_avatar',
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: colorScheme.surface,
                                backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$avatarSeed&backgroundColor=e8f5e9'),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                                radius: 18,
                                backgroundColor: colorScheme.primary,
                                child: const Icon(Icons.verified, color: Colors.white, size: 20)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoCard(context, 'Full Name', email.split('@')[0].toUpperCase(), Icons.person),
                    _buildInfoCard(context, 'Blockchain Identity', email, Icons.email),
                    _buildInfoCard(context, 'Node Status', 'ACTIVE & SYNCED', Icons.check_circle, color: Colors.green),
                    _buildInfoCard(context, 'Registration Date', 'March 20, 2026', Icons.calendar_today),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color ?? colorScheme.primary),
        title: Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

// --- PERMISSIONS AND ROLES SCREEN ---
class PermissionsScreen extends StatelessWidget {
  final String role;
  const PermissionsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    bool canMint = role == 'Farmer';
    bool canTransport = role == 'Logistics Partner';
    bool canTest = role == 'QA Laboratory';
    bool canManufacture = role == 'Manufacturer';

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue.shade800, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          const SettingsHeader(title: 'Roles & Access', icon: Icons.security, color: Color(0xFF1565C0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Blockchain Identity Role', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.blue.shade700, size: 32),
                      const SizedBox(width: 16),
                      Text(role, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Authorized Smart Contract Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildPermissionCard(context, 'Mint Raw Batches', 'Authority to digitize physical herb collections', canMint),
                _buildPermissionCard(context, 'Update Logistics', 'Authority to sign custody transfers in-transit', canTransport),
                _buildPermissionCard(context, 'Submit QA Lab Results', 'Authority to attest AYUSH compliance data', canTest),
                _buildPermissionCard(context, 'Create Product Lots', 'Authority to transform raw assets into products', canManufacture),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context, String title, String desc, bool hasAccess) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: hasAccess ? null : Colors.grey.shade50,
      child: ListTile(
        leading: Icon(hasAccess ? Icons.verified : Icons.lock_outline, color: hasAccess ? Colors.green : Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: hasAccess ? null : Colors.grey)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

// --- APP SETTINGS SCREEN ---
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _notifications = true;
  bool _biometrics = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.orange.shade800, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          const SettingsHeader(title: 'App Preferences', icon: Icons.settings, color: Color(0xFFEF6C00)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildSettingTile('Push Notifications', 'Real-time ledger updates', _notifications, Icons.notifications, (v) => setState(() => _notifications = v)),
                _buildSettingTile('Biometric Sign-In', 'Secure fingerprint authentication', _biometrics, Icons.fingerprint, (v) => setState(() => _biometrics = v)),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.orange),
                  title: const Text('Display Language'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() => _language = _language == 'English' ? 'हिंदी (Hindi)' : 'English');
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Network Status'),
                  subtitle: Text('Hyperledger Fabric v2.5 Online'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, bool value, IconData icon, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Colors.orange),
    );
  }
}

// --- HELP & SUPPORT SCREEN ---
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.purple.shade800, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          const SettingsHeader(title: 'Help Center', icon: Icons.help, color: Color(0xFF6A1B9A)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSupportOption(context, 'Contact Support', 'Get help from network admins', Icons.support_agent),
                _buildSupportOption(context, 'System Status', 'All blockchain nodes at 100%', Icons.cloud_done),
                _buildSupportOption(context, 'Privacy Policy', 'Data compliance & encryption', Icons.privacy_tip),
                const SizedBox(height: 24),
                const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                _buildFaq(context, 'How do I scan a batch?', 'Navigate to the Logistics hub and tap the QR Scanner icon in the bottom right corner.'),
                _buildFaq(context, 'Is my data secure?', 'Yes, all transactions are cryptographically signed and stored on a decentralized immutable ledger.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(BuildContext context, String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  Widget _buildFaq(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      children: [Padding(padding: const EdgeInsets.all(16), child: Text(answer, style: const TextStyle(fontSize: 13, color: Colors.grey)))],
    );
  }
}
