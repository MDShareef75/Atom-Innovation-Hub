import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:atoms_innovation_hub/services/analytics_service.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:atoms_innovation_hub/services/app_service.dart';
import 'package:atoms_innovation_hub/services/blog_service.dart';
import 'package:atoms_innovation_hub/services/contact_service.dart';
import 'package:atoms_innovation_hub/models/app_model.dart';
import 'package:atoms_innovation_hub/models/blog_post_model.dart';
import 'package:atoms_innovation_hub/models/contact_message_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _appAnalytics;
  Map<String, dynamic>? _blogAnalytics;
  Map<String, dynamic>? _userAnalytics;
  
  // Customer search, filter, and sort variables
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'disabled'
  String _roleFilter = 'all'; // 'all', 'admin', 'user'
  String _sortBy = 'name'; // 'name', 'email', 'created'
  bool _sortAscending = true;
  
  // Service instances
  late AppService _appService;
  late BlogService _blogService;
  late ContactService _contactService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Changed from 5 to 6
    _loadAnalytics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize services
    _appService = Provider.of<AppService>(context, listen: false);
    _blogService = Provider.of<BlogService>(context, listen: false);
    _contactService = Provider.of<ContactService>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      
      final appAnalytics = await analyticsService.getAppDownloadAnalytics();
      final blogAnalytics = await analyticsService.getBlogPostEngagementAnalytics();
      final userAnalytics = await analyticsService.getUserAnalytics();
      
      setState(() {
        _appAnalytics = appAnalytics;
        _blogAnalytics = blogAnalytics;
        _userAnalytics = userAnalytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadAnalytics,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dashboard, size: 18, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 6),
                        const Text('Overview'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apps, size: 18, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 6),
                        const Text('Apps'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.article, size: 18, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 6),
                        const Text('Blog'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 18, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 6),
                        const Text('Customers'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.comment, size: 18, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 6),
                        const Text('Comments'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message, size: 18, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 6),
                        const Text('Messages'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<bool>(
        future: authService.isUserAdmin(authService.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final isAdmin = snapshot.data ?? false;
          
          if (!isAdmin) {
            return const Center(
              child: Text('You do not have permission to access the admin dashboard.'),
            );
          }
          
          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildAppsTab(),
                    _buildBlogTab(),
                    _buildCustomersTab(),
                    _buildCommentsTab(),
                    _buildMessagesTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentTab = _tabController.index;
          if (currentTab == 1) {
            _showAddAppDialog();
          } else if (currentTab == 2) {
            _showAddBlogPostDialog();
          } else if (currentTab == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customers are added when they sign up for the app'),
                backgroundColor: Colors.blue,
              ),
            );
          } else if (currentTab == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comments are created by users on blog posts'),
                backgroundColor: Colors.blue,
              ),
            );
          } else if (currentTab == 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Messages are sent by customers through contact form'),
                backgroundColor: Colors.blue,
              ),
            );
          } else {
            _showAddContentDialog();
          }
        },
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading analytics data...'),
          ],
        ),
      );
    }

    if (_appAnalytics == null || _blogAnalytics == null || _userAnalytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load analytics data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Analytics Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.analytics,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time insights and performance metrics',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadAnalytics,
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Analytics Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isMobile = screenWidth < 600;
              
              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernAnalyticsCard(
                            'Total Customers',
                            _userAnalytics!['totalCustomers']?.toString() ?? '0',
                            Icons.people,
                            const Color(0xFF6366F1),
                            '+12%',
                            'vs last month',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernAnalyticsCard(
                            'Total Apps',
                            (_appAnalytics!['apps'] as List).length.toString(),
                            Icons.apps,
                            const Color(0xFF10B981),
                            '+3',
                            'this month',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernAnalyticsCard(
                            'Blog Posts',
                            (_blogAnalytics!['posts'] as List).length.toString(),
                            Icons.article,
                            const Color(0xFFF59E0B),
                            '+5',
                            'this month',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernAnalyticsCard(
                            'Downloads',
                            _appAnalytics!['totalDownloads']?.toString() ?? '0',
                            Icons.download,
                            const Color(0xFFEF4444),
                            '+23%',
                            'vs last month',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildModernAnalyticsCard(
                        'Total Customers',
                        _userAnalytics!['totalCustomers']?.toString() ?? '0',
                        Icons.people,
                        const Color(0xFF6366F1),
                        '+12%',
                        'vs last month',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildModernAnalyticsCard(
                        'Total Apps',
                        (_appAnalytics!['apps'] as List).length.toString(),
                        Icons.apps,
                        const Color(0xFF10B981),
                        '+3',
                        'this month',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildModernAnalyticsCard(
                        'Blog Posts',
                        (_blogAnalytics!['posts'] as List).length.toString(),
                        Icons.article,
                        const Color(0xFFF59E0B),
                        '+5',
                        'this month',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildModernAnalyticsCard(
                        'Downloads',
                        _appAnalytics!['totalDownloads']?.toString() ?? '0',
                        Icons.download,
                        const Color(0xFFEF4444),
                        '+23%',
                        'vs last month',
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),
          
          // Database Management Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Database Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    
                    if (isMobile) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernActionButton(
                                  onPressed: _cleanupSampleData,
                                  icon: Icons.cleaning_services,
                                  label: 'Clear All Data',
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModernActionButton(
                                  onPressed: _loadAnalytics,
                                  icon: Icons.refresh,
                                  label: 'Refresh Analytics',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernActionButton(
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Refreshing customer count...'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    await _loadAnalytics();
                                  },
                                  icon: Icons.people_alt,
                                  label: 'Refresh Customers',
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModernActionButton(
                                  onPressed: _showEditContactInfoDialog,
                                  icon: Icons.edit,
                                  label: 'Edit Contact Info',
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildModernActionButton(
                              onPressed: _cleanupSampleData,
                              icon: Icons.cleaning_services,
                              label: 'Clear All Data',
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildModernActionButton(
                              onPressed: _loadAnalytics,
                              icon: Icons.refresh,
                              label: 'Refresh Analytics',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildModernActionButton(
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Refreshing customer count...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                await _loadAnalytics();
                              },
                              icon: Icons.people_alt,
                              label: 'Refresh Customers',
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildModernActionButton(
                              onPressed: _showEditContactInfoDialog,
                              icon: Icons.edit,
                              label: 'Edit Contact Info',
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.amber[800],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Clear all data will remove all apps and blog posts but keep user accounts. Use this to start fresh.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Modern Charts Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              
              if (isMobile) {
                return Column(
                  children: [
                    _buildModernChartCard(
                      title: 'User Growth',
                      subtitle: 'Daily user growth (last 3 days)',
                      icon: Icons.trending_up,
                      color: const Color(0xFF6366F1),
                      child: SizedBox(
                        height: 280,
                        child: (_userAnalytics!['totalCustomers'] as int) > 0
                            ? _buildModernLineChart()
                            : _buildEmptyChartState(
                                icon: Icons.people_outline,
                                message: 'No user data yet',
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildModernChartCard(
                      title: 'App Downloads',
                      subtitle: 'Download performance by application',
                      icon: Icons.download,
                      color: const Color(0xFF10B981),
                      child: SizedBox(
                        height: 280,
                        child: (_appAnalytics!['totalDownloads'] as int) > 0
                            ? _buildModernBarChart()
                            : _buildEmptyChartState(
                                icon: Icons.download_outlined,
                                message: 'No download data yet',
                              ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildModernChartCard(
                        title: 'User Growth',
                        subtitle: 'Daily user growth (last 3 days)',
                        icon: Icons.trending_up,
                        color: const Color(0xFF6366F1),
                        child: SizedBox(
                          height: 320,
                          child: (_userAnalytics!['totalCustomers'] as int) > 0
                              ? _buildModernLineChart()
                              : _buildEmptyChartState(
                                  icon: Icons.people_outline,
                                  message: 'No user data yet',
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildModernChartCard(
                        title: 'App Downloads',
                        subtitle: 'Download performance by application',
                        icon: Icons.download,
                        color: const Color(0xFF10B981),
                        child: SizedBox(
                          height: 320,
                          child: (_appAnalytics!['totalDownloads'] as int) > 0
                              ? _buildModernBarChart()
                              : _buildEmptyChartState(
                                  icon: Icons.download_outlined,
                                  message: 'No download data yet',
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          // Welcome message if no data
          if ((_appAnalytics!['apps'] as List).isEmpty && (_blogAnalytics!['posts'] as List).isEmpty) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.purple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.rocket_launch,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to your Admin Dashboard!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Get started by adding your first app or blog post using the + button.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isVerySmallMobile = constraints.maxWidth < 400;
                      
                      if (isVerySmallMobile) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _buildModernActionButton(
                                onPressed: _showAddAppDialog,
                                icon: Icons.apps,
                                label: 'Add App',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: _buildModernActionButton(
                                onPressed: _showAddBlogPostDialog,
                                icon: Icons.article,
                                label: 'Add Blog Post',
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModernActionButton(
                              onPressed: _showAddAppDialog,
                              icon: Icons.apps,
                              label: 'Add App',
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 20),
                            _buildModernActionButton(
                              onPressed: _showAddBlogPostDialog,
                              icon: Icons.article,
                              label: 'Add Blog Post',
                              color: const Color(0xFF3B82F6),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppsTab() {
    return StreamBuilder<List<AppModel>>(
      stream: _appService.getApps(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final apps = snapshot.data ?? <AppModel>[];

        if (apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apps_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No applications available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click the + button to add your first app',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                            child: app.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      app.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.apps, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5));
                                      },
                                    ),
                                  )
                                : Icon(Icons.apps, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  app.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatChip(
                                      icon: Icons.download,
                                      label: '${app.downloadCount} downloads',
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatChip(
                                      icon: Icons.new_releases,
                                      label: 'v${app.version}',
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditAppDialog(app),
                                tooltip: 'Edit App',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(
                                  'app',
                                  app.name,
                                  () async => await _appService.deleteApp(app.id),
                                ),
                                tooltip: 'Delete App',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBlogTab() {
    return StreamBuilder<List<BlogPostModel>>(
      stream: _blogService.getBlogPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final posts = snapshot.data ?? <BlogPostModel>[];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No blog posts available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click the + button to add your first blog post',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                            child: post.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      post.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.article, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5));
                                      },
                                    ),
                                  )
                                : Icon(Icons.article, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'By: ${post.authorName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('dd-MM-yyyy').format(post.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditBlogPostDialog(post),
                                tooltip: 'Edit Post',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(
                                  'blog post',
                                  post.title,
                                  () async => await _blogService.deleteBlogPost(post.id),
                                ),
                                tooltip: 'Delete Post',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.visibility,
                                label: 'Views',
                                value: post.viewCount.toString(),
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.comment,
                                label: 'Comments',
                                value: post.commentCount.toString(),
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.thumb_up,
                                label: 'Likes',
                                value: post.likes.length.toString(),
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.thumb_down,
                                label: 'Dislikes',
                                value: post.dislikes.length.toString(),
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    return Container(
      color: const Color(0xFF111827), // Dark background for entire tab
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          List<QueryDocumentSnapshot> allCustomers = snapshot.data?.docs ?? [];
          
          // Filter customers based on search query
          if (_searchQuery.isNotEmpty) {
            allCustomers = allCustomers.where((customer) {
              final data = customer.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery.toLowerCase()) || 
                     email.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          // Filter by status
          if (_statusFilter != 'all') {
            allCustomers = allCustomers.where((customer) {
              final data = customer.data() as Map<String, dynamic>;
              final isDisabled = data['isDisabled'] == true;
              return _statusFilter == 'active' ? !isDisabled : isDisabled;
            }).toList();
          }

          // Filter by role
          if (_roleFilter != 'all') {
            allCustomers = allCustomers.where((customer) {
              final data = customer.data() as Map<String, dynamic>;
              final isAdmin = data['isAdmin'] == true;
              return _roleFilter == 'admin' ? isAdmin : !isAdmin;
            }).toList();
          }

          // Sort customers
          allCustomers.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            
            int comparison = 0;
            switch (_sortBy) {
              case 'name':
                comparison = (dataA['name'] ?? '').toString().compareTo((dataB['name'] ?? '').toString());
                break;
              case 'email':
                comparison = (dataA['email'] ?? '').toString().compareTo((dataB['email'] ?? '').toString());
                break;
              case 'created':
                final dateA = dataA['createdAt'] as Timestamp?;
                final dateB = dataB['createdAt'] as Timestamp?;
                if (dateA != null && dateB != null) {
                  comparison = dateA.compareTo(dateB);
                }
                break;
            }
            
            return _sortAscending ? comparison : -comparison;
          });

          return Column(
            children: [
              // Search, Filter, and Sort Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF374151),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Filter and Sort Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        
                        if (isMobile) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildStatusFilter()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildRoleFilter()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildSortDropdown()),
                                  const SizedBox(width: 12),
                                  _buildSortOrderButton(),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(flex: 2, child: _buildStatusFilter()),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: _buildRoleFilter()),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: _buildSortDropdown()),
                              const SizedBox(width: 12),
                              _buildSortOrderButton(),
                            ],
                          );
                        }
                      },
                    ),
                    
                    // Results count
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${allCustomers.length} customer${allCustomers.length != 1 ? 's' : ''} found',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Customer List
              Expanded(
                child: allCustomers.isEmpty 
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No customers found',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: allCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = allCustomers[index];
                          final data = customer.data() as Map<String, dynamic>;
                          return _buildCustomerCard(customer.id, data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerCard(String customerId, Map<String, dynamic> data) {
    final isDisabled = data['isDisabled'] == true;
    final isAdmin = data['isAdmin'] == true;
    final profilePhotoUrl = data['photoUrl'] ?? '';
    final hasProfilePhoto = profilePhotoUrl.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Dark gray background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisabled ? Colors.red.withOpacity(0.4) : const Color(0xFF374151), // Dark border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDisabled 
                              ? Colors.red.withOpacity(0.3)
                              : const Color(0xFF6366F1).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: isDisabled 
                            ? Colors.red.withOpacity(0.2) 
                            : const Color(0xFF6366F1).withOpacity(0.2),
                        backgroundImage: hasProfilePhoto 
                            ? NetworkImage(profilePhotoUrl)
                            : null,
                        child: !hasProfilePhoto
                            ? Icon(
                                Icons.person,
                                color: isDisabled ? Colors.red[300] : const Color(0xFF8B5CF6),
                                size: 28,
                              )
                            : null,
                      ),
                    ),
                    // Admin badge overlay
                    if (isAdmin)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1F2937), width: 2),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    // Status indicator (online/offline style)
                    if (!isDisabled)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF1F2937), width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDisabled ? Colors.red[300] : Colors.white, // Light text for dark background
                              ),
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.purple[200],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDisabled 
                                  ? Colors.red.withOpacity(0.2) 
                                  : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDisabled 
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isDisabled ? 'DISABLED' : 'ACTIVE',
                              style: TextStyle(
                                color: isDisabled ? Colors.red[300] : Colors.green[300],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data['email'] ?? 'No email',
                              style: TextStyle(
                                color: Colors.grey[300], // Light gray for secondary text
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (hasProfilePhoto) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.photo, size: 14, color: Colors.green[400]),
                            const SizedBox(width: 6),
                            Text(
                              'Has profile photo',
                              style: TextStyle(
                                color: Colors.green[400],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827), // Even darker background for info section
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCustomerInfoItem(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: data['phoneNumber'] ?? 'Not provided',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCustomerInfoItem(
                          icon: Icons.calendar_today,
                          label: 'Joined',
                          value: data['createdAt'] != null 
                              ? DateFormat('dd-MM-yyyy').format((data['createdAt'] as Timestamp).toDate())
                              : 'Unknown',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleCustomerStatus(customerId, !isDisabled),
                    icon: Icon(
                      isDisabled ? Icons.person_add : Icons.person_off,
                      size: 16,
                    ),
                    label: Text(isDisabled ? 'Enable' : 'Disable'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDisabled ? Colors.green[600] : Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCustomerDetails(data),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[300],
                      side: BorderSide(color: Colors.blue[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]), // Lighter gray for dark theme
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400], // Light gray for labels
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // White text for values
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleCustomerStatus(String customerId, bool disable) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .update({'isDisabled': disable});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disable ? 'Customer disabled successfully' : 'Customer enabled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating customer status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCustomerDetails(Map<String, dynamic> customerData) {
    final isDisabled = customerData['isDisabled'] == true;
    final isAdmin = customerData['isAdmin'] == true;
    final profilePhotoUrl = customerData['photoUrl'] ?? '';
    final hasProfilePhoto = profilePhotoUrl.isNotEmpty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937), // Dark background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Customer Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for dark background
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced user header with profile photo
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: isDisabled 
                                ? Colors.red.withOpacity(0.4)
                                : Colors.blue.withOpacity(0.4),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: isDisabled 
                              ? Colors.red.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          backgroundImage: hasProfilePhoto 
                              ? NetworkImage(profilePhotoUrl)
                              : null,
                          child: !hasProfilePhoto
                              ? Icon(
                                  Icons.person, 
                                  color: isDisabled ? Colors.red[300] : Colors.blue, 
                                  size: 32
                                )
                              : null,
                        ),
                      ),
                      // Admin badge overlay
                      if (isAdmin)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1F2937), width: 2),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      // Status indicator
                      if (!isDisabled)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: const Color(0xFF1F2937), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerData['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDisabled ? Colors.red[300] : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isAdmin) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'ADMINISTRATOR',
                                  style: TextStyle(
                                    color: Colors.purple[200],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDisabled 
                                    ? Colors.red.withOpacity(0.2) 
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDisabled 
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isDisabled ? 'DISABLED' : 'ACTIVE',
                                style: TextStyle(
                                  color: isDisabled ? Colors.red[300] : Colors.green[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasProfilePhoto) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.photo, size: 16, color: Colors.green[400]),
                              const SizedBox(width: 6),
                              Text(
                                'Profile photo available',
                                style: TextStyle(
                                  color: Colors.green[400],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              _buildDetailRow('Name', customerData['name'] ?? 'Not provided'),
              _buildDetailRow('Email', customerData['email'] ?? 'Not provided'),
              _buildDetailRow('Phone', customerData['phoneNumber'] ?? 'Not provided'),
              _buildDetailRow('Status', customerData['isDisabled'] == true ? 'Disabled' : 'Active'),
              _buildDetailRow('Admin', customerData['isAdmin'] == true ? 'Yes' : 'No'),
              _buildDetailRow('Profile Photo', hasProfilePhoto ? 'Yes' : 'No'),
              _buildDetailRow('Created', customerData['createdAt'] != null 
                  ? DateFormat('dd MMM yyyy, HH:mm').format((customerData['createdAt'] as Timestamp).toDate())
                  : 'Unknown'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[300], // Light blue for dark theme
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for labels
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[300]), // Light gray for values
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Content'),
        content: const Text('What would you like to add?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddAppDialog();
            },
            child: const Text('Add App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddBlogPostDialog();
            },
            child: const Text('Add Blog Post'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddAppDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final downloadUrlController = TextEditingController();
    final featuresController = TextEditingController();
    final versionController = TextEditingController(text: '1.0.0');
    
    // File upload state
    bool useImageUrl = true;
    bool useDownloadUrl = true;
    PlatformFile? selectedImageFile;
    PlatformFile? selectedApkFile;
    bool isUploading = false;
    String uploadStatus = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.add, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Add New Application',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upload Status
                  if (isUploading) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              uploadStatus,
                              style: TextStyle(
                                color: Colors.green[300],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // App Name field
                  Text(
                    'App Name *',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter app name...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.apps, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description field
                  Text(
                    'Description *',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter app description...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.description, color: Colors.grey[500]),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Image Section
                  Row(
                    children: [
                      Text(
                        'App Image',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: useImageUrl,
                        onChanged: (value) {
                          setState(() {
                            useImageUrl = value;
                            if (!value) selectedImageFile = null;
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                      Text(
                        useImageUrl ? 'URL' : 'Upload',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (useImageUrl) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: TextField(
                        controller: imageUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter image URL (optional)...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                          prefixIcon: Icon(Icons.image, color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.image, color: Colors.grey[500]),
                        title: Text(
                          selectedImageFile?.name ?? 'No image selected',
                          style: TextStyle(
                            color: selectedImageFile != null ? Colors.white : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setState(() {
                                selectedImageFile = result.files.first;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload, size: 16),
                          label: const Text('Select'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Download/APK Section
                  Row(
                    children: [
                      Text(
                        'App Download',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: useDownloadUrl,
                        onChanged: (value) {
                          setState(() {
                            useDownloadUrl = value;
                            if (!value) selectedApkFile = null;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      Text(
                        useDownloadUrl ? 'URL' : 'Upload',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (useDownloadUrl) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: TextField(
                        controller: downloadUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter download URL (optional)...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                          prefixIcon: Icon(Icons.download, color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.android, color: Colors.grey[500]),
                        title: Text(
                          selectedApkFile?.name ?? 'No APK selected',
                          style: TextStyle(
                            color: selectedApkFile != null ? Colors.white : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        subtitle: selectedApkFile != null
                            ? Text(
                                'Size: ${(selectedApkFile!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              )
                            : null,
                        trailing: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['apk'],
                              allowMultiple: false,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setState(() {
                                selectedApkFile = result.files.first;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload, size: 16),
                          label: const Text('Select'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Features field
                  Text(
                    'Features (comma separated)',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: TextField(
                      controller: featuresController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., Fast, Easy to use, Secure',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.star, color: Colors.grey[500]),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Version field
                  Text(
                    'Version *',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: TextField(
                      controller: versionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., 1.0.0',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.new_releases, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[300], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fields marked with * are required. Toggle switches to choose between URL input or file upload.',
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[400],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                await _createAppWithFiles(
                  nameController.text,
                  descriptionController.text,
                  useImageUrl ? imageUrlController.text : '',
                  useDownloadUrl ? downloadUrlController.text : '',
                  featuresController.text,
                  versionController.text,
                  selectedImageFile,
                  selectedApkFile,
                  (status) => setState(() {
                    isUploading = status.isNotEmpty;
                    uploadStatus = status;
                  }),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create App'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAppWithFiles(
    String name,
    String description,
    String imageUrl,
    String downloadUrl,
    String featuresString,
    String version,
    PlatformFile? imageFile,
    PlatformFile? apkFile,
    Function(String) updateStatus,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (version.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Version is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      String finalImageUrl = imageUrl.trim();
      String finalDownloadUrl = downloadUrl.trim();
      String? uploadedImageName;
      String? uploadedApkName;

      // Upload image file if selected
      if (imageFile != null) {
        updateStatus('Uploading image...');
        try {
          finalImageUrl = await _appService.uploadFileFromPicker(
            imageFile,
            'app_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}',
          );
          uploadedImageName = imageFile.name;
        } catch (e) {
          throw Exception('Failed to upload image: $e');
        }
      }

      // Upload APK file if selected
      if (apkFile != null) {
        updateStatus('Uploading APK file...');
        try {
          finalDownloadUrl = await _appService.uploadFileFromPicker(
            apkFile,
            'app_files/${DateTime.now().millisecondsSinceEpoch}_${apkFile.name}',
          );
          uploadedApkName = apkFile.name;
        } catch (e) {
          throw Exception('Failed to upload APK: $e');
        }
      }

      updateStatus('Creating app...');

      // Parse features
      List<String> features = featuresString.isNotEmpty
          ? featuresString
              .split(',')
              .map((feature) => feature.trim())
              .where((feature) => feature.isNotEmpty)
              .toList()
          : [];

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final userModel = currentUser != null 
          ? await authService.userModelStream(currentUser.uid).first
          : null;

      // Use addAppWithDetails to include file metadata
      await _appService.addAppWithDetails(
        name: name.trim(),
        description: description.trim(),
        imageUrl: finalImageUrl,
        downloadUrl: finalDownloadUrl,
        features: features,
        version: version.trim(),
        authorId: currentUser?.uid ?? '',
        authorName: userModel?.name ?? 'Admin',
        uploadedImageName: uploadedImageName,
        uploadedApkName: uploadedApkName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App "${name.trim()}" created successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to the apps tab
                _tabController.animateTo(1);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      updateStatus('');
    }
  }

  void _showAddBlogPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final imageUrlController = TextEditingController();
    final tagsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.add, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Add New Blog Post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title field
                Text(
                  'Title *',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter blog post title...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      prefixIcon: Icon(Icons.title, color: Colors.grey[500]),
                    ),
                    maxLines: 2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Content field
                Text(
                  'Content',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: TextField(
                    controller: contentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter blog post content...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 8,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Image URL field
                Text(
                  'Image URL',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: TextField(
                    controller: imageUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter image URL...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      prefixIcon: Icon(Icons.image, color: Colors.grey[500]),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tags field
                Text(
                  'Tags (comma separated)',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: TextField(
                    controller: tagsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., flutter, mobile, development',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      prefixIcon: Icon(Icons.tag, color: Colors.grey[500]),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Current image preview
                if (post.imageUrl.isNotEmpty) ...[
                  Text(
                    'Current Image',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image failed to load',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Post info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Information',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Author', post.authorName),
                      _buildInfoRow('Created', DateFormat('dd MMM yyyy, HH:mm').format(post.createdAt)),
                      _buildInfoRow('Views', post.viewCount.toString()),
                      _buildInfoRow('Comments', post.commentCount.toString()),
                      _buildInfoRow('Likes', post.likes.length.toString()),
                      _buildInfoRow('Dislikes', post.dislikes.length.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateBlogPost(
                post,
                titleController.text,
                contentController.text,
                imageUrlController.text,
                tagsController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBlogPost(
    BlogPostModel post,
    String title,
    String content,
    String imageUrl,
    String tagsString,
  ) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Parse tags
      List<String> tags = tagsString
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _blogService.updateBlogPost(
        postId: post.id,
        title: title.trim(),
        content: content.trim(),
        imageUrl: imageUrl.trim(),
        tags: tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blog post "${title.trim()}" updated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Could navigate to the blog post if needed
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating blog post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildModernActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildModernChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon, 
                    color: Colors.white, 
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChartState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: 48, 
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLineChart() {
    // Use real user analytics data
    List<FlSpot> userGrowthSpots = [];
    
    if (_userAnalytics != null && _userAnalytics!['monthlyGrowth'] != null) {
      final monthlyData = _userAnalytics!['monthlyGrowth'] as List;
      for (int i = 0; i < monthlyData.length && i < 3; i++) {
        userGrowthSpots.add(FlSpot(i.toDouble(), (monthlyData[i] as num).toDouble()));
      }
    }
    
    // If no real data, show at least some basic data based on total customers
    if (userGrowthSpots.isEmpty) {
      final totalCustomers = (_userAnalytics?['totalCustomers'] as int?) ?? 0;
      // Create a simple growth pattern for the last 3 days (more realistic for recent additions)
      for (int i = 0; i < 3; i++) {
        final value = (totalCustomers * (i + 1) / 3).toDouble();
        userGrowthSpots.add(FlSpot(i.toDouble(), value));
      }
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Show last 3 days with actual dates
                final daysAgo = 2 - value.toInt();
                final date = DateTime.now().subtract(Duration(days: daysAgo));
                
                if (value.toInt() >= 0 && value.toInt() < 3) {
                  return Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: userGrowthSpots,
            isCurved: true,
            color: const Color(0xFF6366F1),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF6366F1),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6366F1).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBarChart() {
    // Use real app analytics data
    List<BarChartGroupData> barGroups = [];
    List<String> appNames = [];
    
    if (_appAnalytics != null && _appAnalytics!['apps'] != null) {
      final apps = _appAnalytics!['apps'] as List;
      for (int i = 0; i < apps.length && i < 4; i++) {
        final app = apps[i] as Map<String, dynamic>;
        final downloads = (app['downloadCount'] as int?) ?? 0;
        final name = (app['name'] as String?) ?? 'App ${i + 1}';
        
        barGroups.add(
          BarChartGroupData(
            x: i, 
            barRods: [BarChartRodData(toY: downloads.toDouble(), color: const Color(0xFF10B981))]
          )
        );
        appNames.add(name.length > 8 ? '${name.substring(0, 8)}...' : name);
      }
    }
    
    // If no real data, create some basic data
    if (barGroups.isEmpty) {
      final totalDownloads = (_appAnalytics?['totalDownloads'] as int?) ?? 0;
      final numApps = 4;
      for (int i = 0; i < numApps; i++) {
        final downloads = (totalDownloads / numApps * (i + 1)).toDouble();
        barGroups.add(
          BarChartGroupData(
            x: i, 
            barRods: [BarChartRodData(toY: downloads, color: const Color(0xFF10B981))]
          )
        );
        appNames.add('App ${i + 1}');
      }
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < appNames.length) {
                  return Text(
                    appNames[value.toInt()],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Future<void> _cleanupSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all apps and blog posts. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete all apps
        final apps = await _appService.getApps().first;
        for (final app in apps) {
          await _appService.deleteApp(app.id);
        }

        // Delete all blog posts
        final posts = await _blogService.getBlogPosts().first;
        for (final post in posts) {
          await _blogService.deleteBlogPost(post.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAnalytics();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditContactInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact Info'),
        content: const Text('Contact info editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF1F2937),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _statusFilter = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _roleFilter,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF1F2937),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Roles')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
            DropdownMenuItem(value: 'user', child: Text('User')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _roleFilter = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF1F2937),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
            DropdownMenuItem(value: 'email', child: Text('Sort by Email')),
            DropdownMenuItem(value: 'created', child: Text('Sort by Join Date')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sortBy = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSortOrderButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            _sortAscending = !_sortAscending;
          });
        },
        icon: Icon(
          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
          color: Colors.grey[400],
        ),
        tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Container(
      color: const Color(0xFF111827), // Dark background
      child: StreamBuilder<List<BlogPostModel>>(
        stream: _blogService.getBlogPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final posts = snapshot.data ?? [];
          
          // Collect all comments from all posts
          List<Map<String, dynamic>> allComments = [];
          for (final post in posts) {
            for (final comment in post.comments) {
              allComments.add({
                'comment': comment,
                'postId': post.id,
                'postTitle': post.title,
              });
            }
          }

          // Sort comments by creation date (newest first)
          allComments.sort((a, b) => 
            (b['comment'] as Comment).createdAt.compareTo((a['comment'] as Comment).createdAt));

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF374151),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.comment,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comments Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${allComments.length} comment${allComments.length != 1 ? 's' : ''} total',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Comments List
              Expanded(
                child: allComments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No comments found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Comments will appear here when users comment on blog posts',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: allComments.length,
                        itemBuilder: (context, index) {
                          final commentData = allComments[index];
                          final comment = commentData['comment'] as Comment;
                          final postId = commentData['postId'] as String;
                          final postTitle = commentData['postTitle'] as String;
                          
                          return _buildCommentCard(comment, postId, postTitle);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentCard(Comment comment, String postId, String postTitle) {
    final isReply = comment.parentId != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReply ? Colors.blue.withOpacity(0.3) : const Color(0xFF374151),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with user profile info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(comment.userId).get(),
              builder: (context, userSnapshot) {
                Map<String, dynamic>? userData;
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  userData = userSnapshot.data!.data() as Map<String, dynamic>;
                }
                
                final isDisabled = userData?['isDisabled'] == true;
                final isAdmin = userData?['isAdmin'] == true;
                final userEmail = userData?['email'] ?? 'Email not available';
                final joinDate = userData?['createdAt'] != null 
                    ? (userData!['createdAt'] as Timestamp).toDate()
                    : null;
                
                return Column(
                  children: [
                    // Main user info row
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isDisabled 
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              backgroundImage: (userData != null && userData['photoUrl'] != null && userData['photoUrl'].isNotEmpty)
                                  ? NetworkImage(userData['photoUrl'])
                                  : null,
                              child: (userData == null || userData['photoUrl'] == null || userData['photoUrl'].isEmpty)
                                  ? Icon(
                                      Icons.person, 
                                      color: isDisabled ? Colors.red[300] : Colors.blue, 
                                      size: 24
                                    )
                                  : null,
                            ),
                            if (isAdmin)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF1F2937), width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                comment.userName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDisabled ? Colors.red[300] : Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isAdmin) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  'ADMIN',
                                                  style: TextStyle(
                                                    color: Colors.purple[200],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (isReply) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  'REPLY',
                                                  style: TextStyle(
                                                    color: Colors.blue[300],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (isDisabled) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  'DISABLED',
                                                  style: TextStyle(
                                                    color: Colors.red[300],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          userEmail,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy • HH:mm').format(comment.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (joinDate != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.person_add, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Joined ${DateFormat('MMM yyyy').format(joinDate)}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _showDeleteCommentDialog(comment, postId, postTitle),
                              tooltip: 'Delete Comment',
                            ),
                            if (userData != null)
                              IconButton(
                                icon: Icon(Icons.person, color: Colors.blue[300], size: 20),
                                onPressed: () => _showUserProfileDialog(userData!, comment.userName),
                                tooltip: 'View User Profile',
                              ),
                          ],
                        ),
                      ],
                    ),
                    
                    // User profile summary card
                    if (userData != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF374151)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildProfileStat(
                                icon: Icons.email,
                                label: 'Email',
                                value: userEmail,
                                color: Colors.blue,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: const Color(0xFF374151),
                            ),
                            Expanded(
                              child: _buildProfileStat(
                                icon: isDisabled ? Icons.block : Icons.check_circle,
                                label: 'Status',
                                value: isDisabled ? 'Disabled' : 'Active',
                                color: isDisabled ? Colors.red : Colors.green,
                              ),
                            ),
                            if (joinDate != null) ...[
                              Container(
                                width: 1,
                                height: 30,
                                color: const Color(0xFF374151),
                              ),
                              Expanded(
                                child: _buildProfileStat(
                                  icon: Icons.calendar_today,
                                  label: 'Member',
                                  value: '${DateTime.now().difference(joinDate).inDays} days',
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Post reference
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Row(
                children: [
                  Icon(Icons.article, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Post: ',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      postTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Comment content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Text(
                comment.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Stats
            Row(
              children: [
                _buildCommentStat(
                  icon: Icons.thumb_up,
                  count: comment.likes.length,
                  label: 'likes',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                Text(
                  'ID: ${comment.id}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showUserProfileDialog(Map<String, dynamic> userData, String userName) {
    final isDisabled = userData['isDisabled'] == true;
    final isAdmin = userData['isAdmin'] == true;
    final joinDate = userData['createdAt'] != null 
        ? (userData['createdAt'] as Timestamp).toDate()
        : null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text(
              'User Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // User header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isDisabled 
                        ? Colors.red.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    backgroundImage: userData['photoUrl'] != null && userData['photoUrl'].isNotEmpty
                        ? NetworkImage(userData['photoUrl'])
                        : null,
                    child: userData['photoUrl'] == null || userData['photoUrl'].isEmpty
                        ? Icon(
                            Icons.person, 
                            color: isDisabled ? Colors.red[300] : Colors.blue, 
                            size: 30
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDisabled ? Colors.red[300] : Colors.white,
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.withOpacity(0.3)),
                            ),
                            child: Text(
                              'ADMINISTRATOR',
                              style: TextStyle(
                                color: Colors.purple[200],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Profile details
              _buildDetailRow('Email', userData['email'] ?? 'Not provided'),
              _buildDetailRow('Phone', userData['phoneNumber'] ?? 'Not provided'),
              _buildDetailRow('Status', isDisabled ? 'Disabled' : 'Active'),
              _buildDetailRow('Role', isAdmin ? 'Administrator' : 'User'),
              _buildDetailRow('User ID', userData['uid'] ?? 'Not available'),
              if (joinDate != null)
                _buildDetailRow('Joined', DateFormat('dd MMM yyyy, HH:mm').format(joinDate)),
              _buildDetailRow('Member for', joinDate != null 
                  ? '${DateTime.now().difference(joinDate).inDays} days'
                  : 'Unknown'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[300],
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentStat({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showDeleteCommentDialog(Comment comment, String postId, String postTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Comment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this comment?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Author: ${comment.userName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Post: $postTitle',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.content,
                    style: TextStyle(color: Colors.grey[300]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[300], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteComment(comment, postId, postTitle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(Comment comment, String postId, String postTitle) async {
    try {
      await _blogService.deleteComment(postId, comment.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment by ${comment.userName} deleted successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo is not available for deleted comments'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMessagesTab() {
    return Container(
      color: const Color(0xFF111827), // Dark background
      child: StreamBuilder<List<ContactMessageModel>>(
        stream: _contactService.getContactMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final messages = snapshot.data ?? [];

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF374151),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.message,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Messages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${messages.length} message${messages.length != 1 ? 's' : ''} total',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats badges
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${messages.where((m) => !m.isRead).length} unread',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${messages.where((m) => m.hasReply).length} replied',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Messages List
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Customer messages will appear here when they contact you',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageCard(message);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(ContactMessageModel message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: message.isRead 
              ? const Color(0xFF374151) 
              : Colors.orange.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sender info and profile picture
            Row(
              children: [
                // Profile picture with user data lookup
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: message.email)
                      .limit(1)
                      .get(),
                  builder: (context, snapshot) {
                    String? photoUrl;
                    bool isAdmin = false;
                    bool isDisabled = false;
                    
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                      photoUrl = userData['photoUrl'];
                      isAdmin = userData['isAdmin'] == true;
                      isDisabled = userData['isDisabled'] == true;
                    }
                    
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDisabled 
                                  ? Colors.red.withOpacity(0.4)
                                  : Colors.green.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isDisabled 
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty 
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: isDisabled ? Colors.red[300] : Colors.green[300],
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                        // Admin badge overlay
                        if (isAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF1F2937), width: 2),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        // Status indicator
                        if (!isDisabled)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF1F2937), width: 1),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!message.isRead) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                'UNREAD',
                                style: TextStyle(
                                  color: Colors.orange[300],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (message.hasReply) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Text(
                                'REPLIED',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              message.email,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        message.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                        color: message.isRead ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      onPressed: () => _toggleMessageReadStatus(message),
                      tooltip: message.isRead ? 'Mark as unread' : 'Mark as read',
                    ),
                    IconButton(
                      icon: Icon(Icons.reply, color: Colors.blue[300], size: 20),
                      onPressed: () => _showReplyDialog(message),
                      tooltip: 'Reply to message',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[300], size: 20),
                      onPressed: () => _showDeleteMessageDialog(message),
                      tooltip: 'Delete message',
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Message subject and info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.subject, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(message.createdAt),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      if (message.phone != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          message.phone!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Message content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            
            // Admin reply section
            if (message.hasReply) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue[300]),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Reply',
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (message.repliedAt != null)
                          Text(
                            DateFormat('MMM dd, HH:mm').format(message.repliedAt!),
                            style: TextStyle(
                              color: Colors.blue[400],
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.adminReply ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (message.repliedByAdminName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Replied by: ${message.repliedByAdminName}',
                        style: TextStyle(
                          color: Colors.blue[400],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMessageReadStatus(ContactMessageModel message) async {
    try {
      // Use Firestore directly to toggle read status since ContactService only supports marking as read
      await FirebaseFirestore.instance
          .collection('contact_messages')
          .doc(message.id)
          .update({'isRead': !message.isRead});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isRead 
                  ? 'Message marked as unread' 
                  : 'Message marked as read'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating message status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReplyDialog(ContactMessageModel message) {
    final replyController = TextEditingController(text: message.adminReply ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.reply, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Reply to Customer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Customer info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer header with profile picture
                      Row(
                        children: [
                          // Customer profile picture
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: message.email)
                                .limit(1)
                                .get(),
                            builder: (context, snapshot) {
                              String? photoUrl;
                              bool isAdmin = false;
                              bool isDisabled = false;
                              
                              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                                photoUrl = userData['photoUrl'];
                                isAdmin = userData['isAdmin'] == true;
                                isDisabled = userData['isDisabled'] == true;
                              }
                              
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDisabled 
                                            ? Colors.red.withOpacity(0.4)
                                            : Colors.blue.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isDisabled 
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.blue.withOpacity(0.2),
                                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty 
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl == null || photoUrl.isEmpty
                                          ? Icon(
                                              Icons.person,
                                              color: isDisabled ? Colors.red[300] : Colors.blue[300],
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                  ),
                                  // Admin badge overlay
                                  if (isAdmin)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF111827), width: 1),
                                        ),
                                        child: const Icon(
                                          Icons.admin_panel_settings,
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer: ${message.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Email: ${message.email}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                Text(
                                  'Subject: ${message.subject}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Original message
                Text(
                  'Original Message:',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Reply field
                Text(
                  'Your Reply:',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: TextField(
                    controller: replyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your reply to the customer...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _sendReply(message, replyController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply(ContactMessageModel message, String reply) async {
    if (reply.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final userModel = currentUser != null 
          ? await authService.userModelStream(currentUser.uid).first
          : null;

      await _contactService.replyToMessage(
        messageId: message.id,
        adminReply: reply.trim(),
        adminId: currentUser?.uid ?? '',
        adminName: userModel?.name ?? 'Admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply sent to ${message.name} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reply: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteMessageDialog(ContactMessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[300], size: 24),
            const SizedBox(width: 8),
            const Text(
              'Delete Message',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this message?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${message.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: ${message.email}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subject: ${message.subject}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.message,
                    style: TextStyle(color: Colors.grey[300]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[300], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The customer will no longer be able to see this message thread.',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessage(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(ContactMessageModel message) async {
    try {
      await _contactService.deleteContactMessage(message.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message from ${message.name} deleted successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo is not available for deleted messages'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAppInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAnalyticsCard(String title, String value, IconData icon, Color color, String trend, String trendLabel) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
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
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon, 
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trendLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String type, String name, Function() onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 