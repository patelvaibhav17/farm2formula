import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_stats_provider.dart';
import '../providers/profile_provider.dart';
import 'profile_settings_screens.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  void _changeAvatar() {
    final seeds = ['Felix', 'Aneka', 'Oliver', 'Mimi', 'Jasper', 'Bandit', 'Scooter', 'Boots'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Avatar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: seeds.map((seed) {
                  return GestureDetector(
                    onTap: () {
                      ref.read(userAvatarProvider.notifier).state = seed;
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$seed&backgroundColor=e8f5e9'),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _changePassword() {
    final curUser = FirebaseAuth.instance.currentUser;
    if (curUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in')));
      return;
    }

    final pwdController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your new password below. It must be at least 6 characters.'),
                const SizedBox(height: 16),
                TextField(
                  controller: pwdController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (pwdController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password too short')));
                    return;
                  }
                  setDialogState(() => isLoading = true);
                  try {
                    await curUser.updatePassword(pwdController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green));
                    }
                  } on FirebaseAuthException catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error'), backgroundColor: Colors.red));
                  } finally {
                    if (context.mounted) setDialogState(() => isLoading = false);
                  }
                },
                child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final avatarSeed = ref.watch(userAvatarProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/role_selection');
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          final String email = user.email ?? 'Unknown User';
          final String roleName = _deriveRole(email);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Animated Gradient Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [Colors.green.shade900, Colors.green.shade700]
                          : [const Color(0xFF2E7D32), const Color(0xFF81C784)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 60), // Status bar spacer
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: InkWell(
                          onTap: _changeAvatar,
                          customBorder: const CircleBorder(),
                          child: Hero(
                            tag: 'profile_avatar',
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: colorScheme.primaryContainer,
                              backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$avatarSeed&backgroundColor=e8f5e9'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Text(
                          '$roleName | Verified Node',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 50), // Bottom padding for overlap effect
                    ],
                  ),
                ),
                
                // Content Body
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Stats Row
                        statsAsync.when(
                          data: (stats) => Row(
                            children: [
                              Expanded(child: _buildStatCard(context, 'Transactions', stats.transactions.toString())),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard(context, 'Trust Score', stats.trustScore)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard(context, 'Badges', stats.badges.toString())),
                            ],
                          ),
                          loading: () => const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                          error: (e, _) => const Text('Failed to load stats'),
                        ),
                        const SizedBox(height: 24),

                        // Menu Options
                        _buildMenuSection(
                          context,
                          title: 'Account & Security',
                          children: [
                            _buildProfileOption(
                              context,
                              title: 'Personal Information',
                              icon: Icons.person_outline,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
                            ),
                            _buildProfileOption(
                              context,
                              title: 'Blockchain Keys',
                              icon: Icons.vpn_key_outlined,
                              onTap: () => _showKeysDialog(context),
                            ),
                            _buildProfileOption(
                              context,
                              title: 'Permissions & Roles',
                              icon: Icons.admin_panel_settings_outlined,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PermissionsScreen(role: roleName))),
                            ),
                            _buildProfileOption(
                              context,
                              title: 'Change Password',
                              icon: Icons.lock_outline,
                              onTap: _changePassword,
                            ),
                          ]
                        ),
                        
                        const SizedBox(height: 24),

                        _buildMenuSection(
                          context,
                          title: 'Preferences',
                          children: [
                            _buildProfileOption(
                              context,
                              title: 'App Settings',
                              icon: Icons.settings_outlined,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
                            ),
                            _buildProfileOption(
                              context,
                              title: 'Help & Support',
                              icon: Icons.help_outline,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                            ),
                          ]
                        ),
                        
                        const SizedBox(height: 80), // Increased Bottom padding to fix overflow
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    ),
  );
}

  String _deriveRole(String email) {
    if (email.contains('farmer')) return 'Farmer';
    if (email.contains('logistics')) return 'Logistics Partner';
    if (email.contains('lab')) return 'QA Laboratory';
    if (email.contains('mfg') || email.contains('manu')) return 'Manufacturer';
    return 'Ecosystem Member';
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, {required String title, required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final int idx = entry.key;
              final Widget child = entry.value;
              return Column(
                children: [
                  child,
                  if (idx < children.length - 1)
                    Divider(height: 1, indent: 64, color: colorScheme.outlineVariant),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
           children: [
             Icon(Icons.construction, color: Colors.white),
             SizedBox(width: 12),
             Text('This feature is coming soon!'),
           ]
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blueGrey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showKeysDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.vpn_key, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('Cryptographic Keys', style: TextStyle(color: colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your identity is securely anchored on the Hyperledger Fabric network.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 16),
            Text('MSP ID:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Text('Org1MSP', style: TextStyle(fontFamily: 'monospace', color: colorScheme.onSurfaceVariant)),
            ),
            Text('Public Key Fingerprint:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Text('a7:f3:b9:22:11:00:c4:e9...', style: TextStyle(fontFamily: 'monospace', color: colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Logout', style: TextStyle(color: colorScheme.onSurface)),
        content: Text('Are you sure you want to log out of your blockchain identity?', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
