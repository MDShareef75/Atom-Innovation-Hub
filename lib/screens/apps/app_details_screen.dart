import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:atoms_innovation_hub/services/app_service.dart';
import 'package:atoms_innovation_hub/services/analytics_service.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:atoms_innovation_hub/models/app_model.dart';
import 'package:intl/intl.dart';
import 'package:atoms_innovation_hub/widgets/rating_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atoms_innovation_hub/services/rating_service.dart';

class AppDetailsScreen extends StatefulWidget {
  final String appId;

  const AppDetailsScreen({super.key, required this.appId});

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> {
  late Future<AppModel?> _appFuture;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  void _loadApp() {
    _appFuture = Provider.of<AppService>(context, listen: false).getAppById(widget.appId);
  }

  Future<void> _downloadApp(AppModel app) async {
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
          app.id,
          app.name,
          authService.currentUser!.uid,
        );
      }
      
      // Increment download count
      await appService.incrementDownloadCount(app.id);
      
      // Launch download URL
      final url = Uri.parse(app.downloadUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Details'),
      ),
      body: FutureBuilder<AppModel?>(
        future: _appFuture,
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

          final app = snapshot.data;

          if (app == null) {
            return const Center(
              child: Text('App not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                if (isMobile) {
                  // Mobile: image on top
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Image
                      Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: app.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: app.imageUrl,
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      width: double.infinity,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.apps,
                                            size: 64,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image not available',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.apps,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image available',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),
                      // Details (as before)
                      _AppDetailsContent(app: app, isMobile: true, isDownloading: _isDownloading, downloadApp: _downloadApp),
                    ],
                  );
                } else {
                  // Desktop/tablet: image on left, details on right
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Image
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: app.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: app.imageUrl,
                                  width: 320,
                                  height: 320,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      width: 320,
                                      height: 320,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.apps,
                                            size: 64,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image not available',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.apps,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image available',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(width: 32),
                      // Details (as before)
                      Expanded(
                        child: _AppDetailsContent(app: app, isMobile: false, isDownloading: _isDownloading, downloadApp: _downloadApp),
                      ),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    return formatter.format(date);
  }
}

class _AppDetailsContent extends StatelessWidget {
  final AppModel app;
  final bool isMobile;
  final bool isDownloading;
  final Future<void> Function(AppModel) downloadApp;

  const _AppDetailsContent({
    required this.app,
    required this.isMobile,
    required this.isDownloading,
    required this.downloadApp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Name and Version
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      app.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${app.downloadCount}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<double>(
                      future: RatingService().getAverageRating(app.id),
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
                const Text('Downloads'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Description
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          app.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        // Ratings Section
        Builder(
          builder: (context) {
            final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
            return Column(
              children: [
                if (userId.isNotEmpty) RatingWidget(appId: app.id, userId: userId),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Features
        if (app.features.isNotEmpty) ...[
          Text(
            'Features',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: app.features.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        app.features[index],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        // File Information (if available)
        if (app.uploadedImageName != null || app.uploadedApkName != null) ...[
          Text(
            'File Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (app.uploadedImageName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.image, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image: ${app.uploadedImageName}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (app.imageUploadedAt != null)
                                Text(
                                  'Uploaded: ${DateFormat('dd-MM-yyyy').format(app.imageUploadedAt!)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (app.uploadedApkName != null) const SizedBox(height: 12),
                  ],
                  if (app.uploadedApkName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.android, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'APK: ${app.uploadedApkName}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (app.apkUploadedAt != null)
                                Text(
                                  'Uploaded: ${DateFormat('dd-MM-yyyy').format(app.apkUploadedAt!)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Download Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isDownloading ? null : () => downloadApp(app),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            icon: isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(isDownloading ? 'Downloading...' : 'Download App'),
          ),
        ),
        const SizedBox(height: 16),
        // Release Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Released: ${DateFormat('dd-MM-yyyy').format(app.releaseDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Last Updated: ${DateFormat('dd-MM-yyyy').format(app.lastUpdated)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
} 