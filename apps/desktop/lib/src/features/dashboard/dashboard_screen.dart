import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../widgets/stats_card.dart';
import '../widgets/recent_projects.dart';
import '../widgets/ai_assistant_card.dart';
import '../widgets/quick_actions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Photographer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s what\'s happening with your projects today.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action'))),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.cloud_outlined),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action'))),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Total Images',
                        value: '12,847',
                        icon: Icons.photo_outlined,
                        color: Colors.blue,
                        change: '+12%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Projects',
                        value: '23',
                        icon: Icons.folder_outlined,
                        color: Colors.green,
                        change: '+3',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'AI Edits',
                        value: '1,456',
                        icon: Icons.auto_awesome_outlined,
                        color: Colors.purple,
                        change: '+28%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Storage Used',
                        value: '24.5 GB',
                        icon: Icons.storage_outlined,
                        color: Colors.orange,
                        change: '68% left',
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                // Quick Actions
                const QuickActions().animate().fadeIn(duration: 300.ms, delay: 100.ms),
                const SizedBox(height: 24),
                // Main Content Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Projects
                    Expanded(
                      flex: 2,
                      child: const RecentProjects().animate().fadeIn(duration: 300.ms, delay: 200.ms),
                    ),
                    const SizedBox(width: 24),
                    // AI Assistant
                    Expanded(
                      child: const AiAssistantCard().animate().fadeIn(duration: 300.ms, delay: 300.ms),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
