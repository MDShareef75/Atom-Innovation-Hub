import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:atoms_innovation_hub/providers/theme_provider.dart';
import 'package:atoms_innovation_hub/widgets/theme_switch_widget.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:atoms_innovation_hub/services/app_service.dart';
import 'package:atoms_innovation_hub/services/blog_service.dart';
import 'package:atoms_innovation_hub/models/app_model.dart';
import 'package:atoms_innovation_hub/models/blog_post_model.dart';
import 'package:atoms_innovation_hub/models/user_model.dart';
import 'package:atoms_innovation_hub/widgets/theme_switch_widget.dart';
import 'package:atoms_innovation_hub/widgets/copyright_footer.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  final Widget child;
  
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  Future<void> _checkIfAdmin() async {
    setState(() {
      _isCheckingAdmin = true;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      print('🔍 HomeScreen: Checking admin status for user: ${authService.currentUser!.uid}');
      print('📧 HomeScreen: User email: ${authService.currentUser!.email}');
      
      final isAdmin = await authService.isUserAdmin(authService.currentUser!.uid);
      print('✅ HomeScreen: Admin check result: $isAdmin');
      
      setState(() {
        _isAdmin = isAdmin;
        _isCheckingAdmin = false;
      });
      print('🔄 HomeScreen: _isAdmin state updated to: $_isAdmin');
      _updateSelectedIndex();
    } else {
      print('❌ HomeScreen: No current user found');
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') {
      setState(() => _selectedIndex = 0);
    } else if (location.startsWith('/apps')) {
      setState(() => _selectedIndex = 1);
    } else if (location.startsWith('/blog')) {
      setState(() => _selectedIndex = 2);
    } else if (location == '/messages') {
      if (!_isAdmin) {
        setState(() => _selectedIndex = 3);
      }
    } else if (location == '/admin') {
      setState(() => _selectedIndex = _isAdmin ? 3 : 4);
    }
  }

  void _onDestinationSelected(int index) {
    if (_isAdmin) {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/apps');
          break;
        case 2:
          context.go('/blog');
          break;
        case 3:
          context.go('/admin');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/apps');
          break;
        case 2:
          context.go('/blog');
          break;
        case 3:
          context.go('/messages');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Debug output every time build is called
    print('🎨 HomeScreen BUILD: _isAdmin = $_isAdmin, _isCheckingAdmin = $_isCheckingAdmin, _selectedIndex = $_selectedIndex');
    
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0), top: Radius.circular(0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.blue.withOpacity(0.10),
                    Colors.purple.withOpacity(0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 2,
        scrolledUnderElevation: 4,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo is outside the blur effect, so it's always clear
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, // No blur or overlay
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/atom_intelligence_at_core.png',
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATOM Innovation Hub',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    fontSize: 22,
                    shadows: [
                      Shadow(
                        color: Colors.blueAccent.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Intelligence at the Core',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.cyanAccent.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Profile Section
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.currentUser == null) {
                  return const SizedBox.shrink();
                }

                return StreamBuilder<UserModel?>(
                  stream: authService.userModelStream(authService.currentUser!.uid),
                  builder: (context, snapshot) {
                    final userModel = snapshot.data;
                    final authUser = authService.currentUser;
                    
                    // Debug logging for profile data
                    print('🔍 NAVIGATION PROFILE DEBUG:');
                    print('   - User ID: ${authUser?.uid}');
                    print('   - User Email: ${authUser?.email}');
                    print('   - UserModel exists: ${userModel != null}');
                    print('   - UserModel name: ${userModel?.name}');
                    print('   - UserModel photoUrl: "${userModel?.photoUrl}"');
                    print('   - PhotoUrl isEmpty: ${userModel?.photoUrl?.isEmpty}');
                    print('   - PhotoUrl length: ${userModel?.photoUrl?.length}');
                    print('   - Snapshot connection state: ${snapshot.connectionState}');
                    print('   - Snapshot hasData: ${snapshot.hasData}');
                    print('   - Snapshot hasError: ${snapshot.hasError}');
                    if (snapshot.hasError) {
                      print('   - Snapshot error: ${snapshot.error}');
                    }
                    
                    return PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(2), // Reduced padding for image
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildTopProfileImage(userModel, authUser),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      offset: const Offset(0, 40),
                      onSelected: (value) {
                        switch (value) {
                          case 'about':
                            context.go('/about');
                            break;
                          case 'contact':
                            context.go('/contact');
                            break;
                          case 'profile':
                            context.go('/profile');
                            break;
                          case 'logout':
                            Provider.of<AuthService>(context, listen: false).signOut(clearRememberedCredentials: false);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        // User Info Header
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      child: ClipOval(
                                        child: _buildPopupProfileImage(userModel, authUser),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userModel?.name ?? authUser?.displayName ?? authUser?.email?.split('@')[0] ?? 'User',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (authUser?.email != null)
                                            Text(
                                              authUser!.email!,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _isAdmin ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _isAdmin ? Colors.purple.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              _isAdmin ? 'ADMIN' : 'USER',
                                              style: TextStyle(
                                                color: _isAdmin ? Colors.purple[700] : Colors.blue[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                  height: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Theme Toggle
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.palette_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Theme',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const ThemeSwitchWidget(
                                  showLabel: false,
                                  width: 50,
                                  height: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Profile
                        PopupMenuItem(
                          value: 'profile',
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // About
                        PopupMenuItem(
                          value: 'about',
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.info_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Contact
                        PopupMenuItem(
                          value: 'contact',
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.contact_mail_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Contact',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Divider before logout
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Divider(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            height: 1,
                          ),
                        ),
                        
                        // Logout
                        PopupMenuItem(
                          value: 'logout',
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.1),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: widget.child,
      floatingActionButton: null,
      bottomNavigationBar: _isCheckingAdmin 
          ? Container(
              height: 85,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 85,
                  margin: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.10),
                        Colors.blue.withOpacity(0.10),
                        Colors.purple.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                        spreadRadius: 0,
                      ),
                    ],
                    // No border for glass effect
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          context: context,
                          icon: Icons.home_rounded,
                          selectedIcon: Icons.home,
                          label: 'Home',
                          index: 0,
                          isSelected: _selectedIndex == 0,
                        ),
                        _buildNavItem(
                          context: context,
                          icon: Icons.apps_rounded,
                          selectedIcon: Icons.apps,
                          label: 'Apps',
                          index: 1,
                          isSelected: _selectedIndex == 1,
                        ),
                        _buildNavItem(
                          context: context,
                          icon: Icons.article_rounded,
                          selectedIcon: Icons.article,
                          label: 'Blog',
                          index: 2,
                          isSelected: _selectedIndex == 2,
                        ),
                        ...() {
                          List<Widget> items = [];
                          if (!_isAdmin) {
                            items.add(
                              _buildNavItem(
                                context: context,
                                icon: Icons.message_rounded,
                                selectedIcon: Icons.message,
                                label: 'Messages',
                                index: 3,
                                isSelected: _selectedIndex == 3,
                              ),
                            );
                          }
                          if (_isAdmin) {
                            items.add(
                              _buildNavItem(
                                context: context,
                                icon: Icons.admin_panel_settings_rounded,
                                selectedIcon: Icons.admin_panel_settings,
                                label: 'Admin',
                                index: 3,
                                isSelected: _selectedIndex == 3,
                              ),
                            );
                          }
                          return items;
                        }(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          _onDestinationSelected(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                    ],
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  size: isSelected ? 26 : 24,
                  color: isSelected 
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProfileImage(UserModel? userModel, User? authUser) {
    print('🖼️ Building top profile image - userModel: ${userModel?.name}, photoUrl: ${userModel?.photoUrl}');
    
    if (userModel?.photoUrl?.isNotEmpty == true) {
      print('✅ Profile image URL found: ${userModel!.photoUrl}');
      
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: userModel.photoUrl!,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    print('📝 No profile image, showing initials for: ${userModel?.name ?? authUser?.displayName ?? authUser?.email}');
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Center(
        child: Text(
          userModel?.name?.isNotEmpty == true 
              ? userModel!.name[0].toUpperCase() 
              : authUser?.displayName?.isNotEmpty == true
                  ? authUser!.displayName![0].toUpperCase()
                  : authUser?.email?.isNotEmpty == true
                      ? authUser!.email![0].toUpperCase()
                      : 'U',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPopupProfileImage(UserModel? userModel, User? authUser) {
    print('🖼️ Building popup profile image - userModel: ${userModel?.name}, photoUrl: ${userModel?.photoUrl}');
    
    if (userModel?.photoUrl?.isNotEmpty == true) {
      print('✅ Popup profile image URL found: ${userModel!.photoUrl}');
      return CachedNetworkImage(
        imageUrl: userModel.photoUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    }
    
    print('📝 No popup profile image, showing initials for: ${userModel?.name ?? authUser?.displayName ?? authUser?.email}');
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Center(
        child: Text(
          userModel?.name?.isNotEmpty == true 
              ? userModel!.name[0].toUpperCase() 
              : authUser?.displayName?.isNotEmpty == true
                  ? authUser!.displayName![0].toUpperCase()
                  : authUser?.email?.isNotEmpty == true
                      ? authUser!.email![0].toUpperCase()
                      : 'U',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              final isMobile = screenWidth < 600;
              final isTablet = screenWidth >= 600 && screenWidth < 900;
              
              // Calculate responsive height based on screen size
              double containerHeight;
              if (isMobile) {
                containerHeight = screenHeight * 0.6; // Increased from 55% to 60% for mobile
                containerHeight = containerHeight.clamp(450.0, 550.0); // Increased min from 420 to 450, max from 500 to 550
              } else if (isTablet) {
                containerHeight = screenHeight * 0.5; // Increased from 45% to 50% for tablet
                containerHeight = containerHeight.clamp(400.0, 500.0); // Increased min from 350 to 400, max from 450 to 500
              } else {
                containerHeight = screenHeight * 0.45; // Increased from 40% to 45% for desktop
                containerHeight = containerHeight.clamp(380.0, 450.0); // Increased min from 320 to 380, max from 400 to 450
              }
              
              return Container(
                width: double.infinity,
                height: containerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/ai-generated-9104187.jpg'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.blue.withOpacity(0.3),
                        Colors.purple.withOpacity(0.4),
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Main content
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 24 : isTablet ? 32 : 40,
                            vertical: isMobile ? 32 : isTablet ? 36 : 40,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 6 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ATOM Logo
                                    Image.asset(
                                      'assets/images/atom_intelligence_at_core.png',
                                      height: isMobile ? 16 : 18,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Innovation Hub',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobile ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: isMobile ? 20 : 24),
                              
                              // Main title with gradient text effect
                              Container(
                                width: double.infinity,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.white, Colors.white70],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    'Welcome to\nATOM Innovation Hub',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 28 : isTablet ? 36 : 40,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(0, 4),
                                          blurRadius: 12,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: isMobile ? 16 : 20),
                              
                              // Subtitle
                              Text(
                                'Intelligence at the Core - Discover innovative applications, insightful blog posts, and cutting-edge technology solutions.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isMobile ? 16 : 18,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              
                              SizedBox(height: isMobile ? 28 : 32),
                              
                              // Action buttons with perfect alignment
                              if (isMobile)
                                Column(
                                  children: [
                                    _buildGlassButton(
                                      context: context,
                                      onPressed: () => context.go('/apps'),
                                      icon: Icons.apps,
                                      label: 'Explore Apps',
                                      isPrimary: true,
                                      isFullWidth: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildGlassButton(
                                      context: context,
                                      onPressed: () => context.go('/blog'),
                                      icon: Icons.article,
                                      label: 'Read Blog',
                                      isPrimary: false,
                                      isFullWidth: true,
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    _buildGlassButton(
                                      context: context,
                                      onPressed: () => context.go('/apps'),
                                      icon: Icons.apps,
                                      label: 'Explore Apps',
                                      isPrimary: true,
                                      isFullWidth: false,
                                    ),
                                    const SizedBox(width: 20),
                                    _buildGlassButton(
                                      context: context,
                                      onPressed: () => context.go('/blog'),
                                      icon: Icons.article,
                                      label: 'Read Blog',
                                      isPrimary: false,
                                      isFullWidth: false,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Floating stats cards (only on tablet and desktop)
                      if (!isMobile)
                        Positioned(
                          top: 24,
                          right: 24,
                          child: Column(
                            children: [
                              StreamBuilder<List<AppModel>>(
                                stream: Provider.of<AppService>(context, listen: false).getApps(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.length ?? 0;
                                  return _buildFloatingStatCard(
                                    icon: Icons.apps,
                                    label: 'Apps',
                                    value: count > 0 ? '$count' : '-',
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              StreamBuilder<List<BlogPostModel>>(
                                stream: Provider.of<BlogService>(context, listen: false).getBlogPosts(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.length ?? 0;
                                  return _buildFloatingStatCard(
                                    icon: Icons.article,
                                    label: 'Posts',
                                    value: count > 0 ? '$count' : '-',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Featured Apps Section
          Text(
            'Featured Apps',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AppModel>>(
            stream: Provider.of<AppService>(context, listen: false).getApps(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('Error loading apps: ${snapshot.error}'),
                  ),
                );
              }
              
              final apps = snapshot.data ?? [];
              
              if (apps.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apps_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No apps available yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new applications',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SizedBox(
                height: isMobile ? 220 : 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: apps.length > 6 ? 6 : apps.length, // Show max 6 apps
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return GestureDetector(
                      onTap: () {
                        context.go('/apps/details/${app.id}');
                      },
                      child: Card(
                        margin: const EdgeInsets.only(right: 16),
                        child: Container(
                          width: isMobile ? 160 : 140,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // App icon and info row
                              Row(
                                children: [
                                  app.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: app.imageUrl,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.apps, size: 40),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'v${app.version}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd-MM-yyyy').format(app.releaseDate),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                app.name,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  app.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Like/Dislike buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Like/Dislike Buttons
                                  Consumer<AuthService>(
                                    builder: (context, authService, child) {
                                      final userId = authService.currentUser?.uid;
                                      final isLiked = userId != null && app.likes.contains(userId);
                                      final isDisliked = userId != null && app.dislikes.contains(userId);
                                      
                                      return Row(
                                        children: [
                                          // Like Button
                                          InkWell(
                                            onTap: userId != null ? () async {
                                              try {
                                                await Provider.of<AppService>(context, listen: false)
                                                    .likeApp(app.id, userId);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error: $e')),
                                                );
                                              }
                                            } : null,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: EdgeInsets.all(isMobile ? 8 : 6),
                                              decoration: BoxDecoration(
                                                color: isLiked ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isLiked ? Colors.blue : Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                                    color: isLiked ? Colors.blue : Colors.grey[600],
                                                    size: isMobile ? 16 : 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${app.likes.length}',
                                                    style: TextStyle(
                                                      fontSize: isMobile ? 12 : 10,
                                                      color: isLiked ? Colors.blue : Colors.grey[600],
                                                      fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(width: 8),
                                          
                                          // Dislike Button
                                          InkWell(
                                            onTap: userId != null ? () async {
                                              try {
                                                await Provider.of<AppService>(context, listen: false)
                                                    .dislikeApp(app.id, userId);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error: $e')),
                                                );
                                              }
                                            } : null,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: EdgeInsets.all(isMobile ? 8 : 6),
                                              decoration: BoxDecoration(
                                                color: isDisliked ? Colors.red.withOpacity(0.1) : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isDisliked ? Colors.red : Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                                    color: isDisliked ? Colors.red : Colors.grey[600],
                                                    size: isMobile ? 16 : 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${app.dislikes.length}',
                                                    style: TextStyle(
                                                      fontSize: isMobile ? 12 : 10,
                                                      color: isDisliked ? Colors.red : Colors.grey[600],
                                                      fontWeight: isDisliked ? FontWeight.bold : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Recent Blog Posts Section
          Text(
            'Recent Blog Posts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BlogPostModel>>(
            stream: Provider.of<BlogService>(context, listen: false).getBlogPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading blog posts: ${snapshot.error}'),
                );
              }
              
              final posts = snapshot.data ?? [];
              
              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No blog posts available yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new articles',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return SizedBox(
                height: isMobile ? 350 : 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: posts.length > 6 ? 6 : posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return GestureDetector(
                      onTap: () {
                        context.go('/blog/post/${post.id}');
                      },
                      child: Container(
                        width: isMobile ? screenWidth * 0.85 : 320,
                        margin: const EdgeInsets.only(right: 16),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // Background Image or Color
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                child: post.imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: post.imageUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context).colorScheme.primary,
                                              Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                              
                              // Light Gradient Overlay for better text contrast
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.1),
                                      Colors.black.withOpacity(0.4),
                                    ],
                                    stops: const [0.0, 0.5, 0.8, 1.0],
                                  ),
                                ),
                              ),
                              
                              // Content
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 16 : 18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.5),
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Title
                                      Text(
                                        post.title.isNotEmpty ? post.title : 'Untitled Post',
                                        style: TextStyle(
                                          fontSize: isMobile ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 4,
                                              color: Colors.black.withOpacity(0.8),
                                            ),
                                            Shadow(
                                              offset: const Offset(1, 1),
                                              blurRadius: 2,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Description
                                      Text(
                                        post.content.isNotEmpty 
                                          ? (post.content.length > 80 
                                              ? '${post.content.substring(0, 80)}...' 
                                              : post.content)
                                          : 'No content available',
                                        style: TextStyle(
                                          fontSize: isMobile ? 13 : 14,
                                          color: Colors.white.withOpacity(0.95),
                                          height: 1.3,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                              color: Colors.black.withOpacity(0.6),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Date and Stats Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Date
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('dd-MM-yyyy').format(post.createdAt),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Stats
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.thumb_up,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${post.likes.length}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.visibility,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${post.viewCount}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Read More Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            context.go('/blog/post/${post.id}');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Theme.of(context).colorScheme.primary,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: isMobile ? 12 : 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: Text(
                                            'Read More',
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Reduced bottom padding to prevent overflow
          const SizedBox(height: 16),
          
          // Copyright Footer
          const CopyrightFooter(),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isFullWidth,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : 180,
      height: 64, // Fixed height for perfect alignment
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPrimary 
            ? [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ]
            : [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.05),
              ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(isPrimary ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          if (isPrimary)
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 64, // Ensure consistent height
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Perfect vertical alignment
              children: [
                Icon(
                  icon, 
                  size: 22,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
} 