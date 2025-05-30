import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'assets/images/atom_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.hub,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About ATOM Innovation Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intelligence at the Core',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Mission Section
            _buildSection(
              context,
              'Our Mission',
              'ATOM Innovation Hub represents "Intelligence at the Core" - a cutting-edge platform designed to showcase innovative applications, share insightful blog posts, and foster a community of technology enthusiasts. We believe in the power of intelligent innovation to transform ideas into reality and drive the future forward.',
              Icons.rocket_launch,
            ),
            
            const SizedBox(height: 24),
            
            // Vision Section
            _buildSection(
              context,
              'Our Vision',
              'To become the leading platform where intelligence meets innovation, where developers, innovators, and technology enthusiasts come together to share, discover, and collaborate on groundbreaking applications and ideas that shape the future of technology.',
              Icons.visibility,
            ),
            
            const SizedBox(height: 24),
            
            // Features Section
            _buildSection(
              context,
              'What We Offer',
              '',
              Icons.star,
              features: [
                'Innovative Application Showcase',
                'Insightful Technology Blog Posts',
                'User-Friendly Interface',
                'Community Engagement Features',
                'Real-time Analytics and Insights',
                'Secure User Authentication',
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Technology Stack
            _buildSection(
              context,
              'Built With',
              'Atom\'s Innovation Hub is built using modern technologies to ensure performance, scalability, and user experience.',
              Icons.code,
              features: [
                'Flutter - Cross-platform UI framework',
                'Firebase - Backend and authentication',
                'Firestore - Real-time database',
                'Firebase Storage - File storage',
                'Material Design 3 - Modern UI components',
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Team Section
            _buildSection(
              context,
              'The Team',
              'ATOM Innovation Hub is developed with passion by a dedicated team committed to creating exceptional digital experiences and fostering intelligent innovation in the technology community.',
              Icons.group,
            ),
            
            const SizedBox(height: 32),
            
            // Copyright Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.copyright,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Copyright & Legal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2025 ATOM Innovation Hub. All rights reserved.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ATOM logo and "Intelligence at the Core" are trademarks of ATOM Innovation Hub. All product names, logos, and brands are property of their respective owners.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This platform is designed to showcase innovation and foster technology community engagement.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Call to Action
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Join Our Community',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Discover amazing applications, read insightful blog posts, and be part of our growing innovation community.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              context.go('/apps');
                            },
                            icon: const Icon(Icons.explore),
                            label: const Text('Explore Apps'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              context.go('/blog');
                            },
                            icon: const Icon(Icons.article),
                            label: const Text('Read Blog'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    IconData icon, {
    List<String>? features,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (features != null) ...[
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
} 