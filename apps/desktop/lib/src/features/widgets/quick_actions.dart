import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickActionButton(
                  context,
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Import Images',
                  color: Colors.blue,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Cull',
                  color: Colors.purple,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: Colors.green,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: 'Create Gallery',
                  color: Colors.orange,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
