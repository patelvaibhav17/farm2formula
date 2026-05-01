import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarSeed = ref.watch(userAvatarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(20),
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$avatarSeed&backgroundColor=e8f5e9'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRoleCard(
            context,
            title: 'Farmer / Collector',
            description: 'Register harvested herb batches and capture GPS data.',
            icon: Icons.agriculture,
            route: '/harvesting',
          ),
          _buildRoleCard(
            context,
            title: 'Transporter',
            description: 'Update shipment status and track movement.',
            icon: Icons.local_shipping,
            route: '/logistics',
          ),
          _buildRoleCard(
            context,
            title: 'Laboratory',
            description: 'Upload test certificates and verify herb quality.',
            icon: Icons.science,
            route: '/laboratory',
          ),
          _buildRoleCard(
            context,
            title: 'Manufacturer',
            description: 'Create products from verified batches and generate QR codes.',
            icon: Icons.factory,
            route: '/manufacturing',
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context,
      {required String title,
      required String description,
      required IconData icon,
      required String route}) {
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
