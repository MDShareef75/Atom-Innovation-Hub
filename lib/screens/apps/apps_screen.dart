import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:atoms_innovation_hub/services/app_service.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:atoms_innovation_hub/services/analytics_service.dart';
import 'package:atoms_innovation_hub/models/app_model.dart';
import 'package:intl/intl.dart';
import 'package:atoms_innovation_hub/widgets/rating_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atoms_innovation_hub/services/rating_service.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<AppModel>>(
        stream: Provider.of<AppService>(context, listen: false).getApps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final apps = snapshot.data ?? [];

          if (apps.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No applications available yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new applications',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return _buildAppsList(context, apps);
        },
      ),
    );
  }

  Widget _buildAppsList(BuildContext context, List<AppModel> apps) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Center',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover and download applications created by Atom',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final app = apps[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AppCard(app: app),
                );
              },
              childCount: apps.length,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 16),
        ),
      ],
    );
  }
}

class _AppCard extends StatefulWidget {
  final AppModel app;

  const _AppCard({required this.app});

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  bool _isDownloading = false;

  Future<void> _downloadApp() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final appService = Provider.of<AppService>(context, listen: false);
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      
      // Log download event
      if (authService.currentUser != null) {
        await analyticsService.logAppDownload(
          widget.app.id,
          widget.app.name,
          authService.currentUser!.uid,
        );
      }
      
      // Increment download count
      await appService.incrementDownloadCount(widget.app.id);
      
      // Launch download URL
      final url = Uri.parse(widget.app.downloadUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch download URL');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download started for ${widget.app.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return InkWell(
      onTap: () {
        context.go('/apps/details/${widget.app.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: widget.app.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: widget.app.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(Icons.apps, size: 40),
                      ),
                    )
                  : const Icon(Icons.apps, size: 40),
            ),
            const SizedBox(width: 16),
            
            // App Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.app.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.app.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.new_releases,
                        label: 'v${widget.app.version}',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: Icons.download,
                        label: '${widget.app.downloadCount}',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<double>(
                        future: RatingService().getAverageRating(widget.app.id),
                        builder: (context, snapshot) {
                          final rating = snapshot.data ?? 0.0;
                          return Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Release Date
        Text(
          'Released: ${DateFormat('dd-MM-yyyy').format(widget.app.releaseDate)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action Row
        Row(
          children: [
            const Spacer(),
            // Download Button
            if (widget.app.downloadUrl.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadApp,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, size: 20),
                label: Text(_isDownloading ? 'Downloading...' : 'Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: widget.app.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.app.imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.apps, size: 60),
                  ),
                )
              : const Icon(Icons.apps, size: 60),
        ),
        const SizedBox(width: 24),
        
        // App Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.app.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.app.description,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // Stats Row
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.new_releases,
                    label: 'v${widget.app.version}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.download,
                    label: '${widget.app.downloadCount} downloads',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<double>(
                    future: RatingService().getAverageRating(widget.app.id),
                    builder: (context, snapshot) {
                      final rating = snapshot.data ?? 0.0;
                      return Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.calendar_today,
                    label: DateFormat('dd-MM-yyyy').format(widget.app.releaseDate),
                    color: Colors.orange,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action Row
              Row(
                children: [
                  const Spacer(),
                  // Download Button
                  if (widget.app.downloadUrl.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadApp,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download, size: 24),
                      label: Text(_isDownloading ? 'Downloading...' : 'Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 