import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:atoms_innovation_hub/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  Uint8List? _webImage;
  String? _imageName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (kIsWeb) {
        // For web platform
        final bytes = await image.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageName = image.name;
          _selectedImage = null; // Clear mobile file
        });
      } else {
        // For mobile platforms
        setState(() {
          _selectedImage = File(image.path);
          _webImage = null; // Clear web bytes
          _imageName = null;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.uid;
        
        if (userId != null) {
          await authService.updateProfile(
            userId: userId,
            name: _nameController.text.trim(),
            imageFile: _selectedImage,
            webImageBytes: _webImage,
            imageName: _imageName,
          );
          
          // Don't clear selected image immediately - let Firestore stream update
          // The image will be cleared when the stream provides the new photoUrl
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear the selected images after a short delay to allow Firestore to update
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _selectedImage = null;
                _webImage = null;
                _imageName = null;
              });
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.currentUser == null) {
      return const Center(
        child: Text('Please log in to view your profile'),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<UserModel?>(
            stream: authService.userModelStream(authService.currentUser!.uid),
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

              final user = snapshot.data;

              if (user == null) {
                return const Center(
                  child: Text('User data not found'),
                );
              }

              // Initialize name controller if not already set
              if (_nameController.text.isEmpty) {
                _nameController.text = user.name;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Header
                    Text(
                      'My Profile',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Profile Picture
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              child: ClipOval(
                                child: _buildProfileImage(user),
                              ),
                            ),
                            if (_isLoading)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        if (_selectedImage != null || _webImage != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'New photo selected. Click "Update Profile" to save.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // User Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Information',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Responsive layout for mobile
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isMobile = constraints.maxWidth < 600;
                                      
                                      if (isMobile) {
                                        return Column(
                                          children: [
                                            TextFormField(
                                              controller: _nameController,
                                              decoration: const InputDecoration(
                                                labelText: 'Name',
                                                prefixIcon: Icon(Icons.person),
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your name';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              initialValue: user.email,
                                              decoration: const InputDecoration(
                                                labelText: 'Email',
                                                prefixIcon: Icon(Icons.email),
                                                border: OutlineInputBorder(),
                                              ),
                                              readOnly: true,
                                            ),
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              initialValue: user.isAdmin ? 'Admin' : 'Regular User',
                                              decoration: const InputDecoration(
                                                labelText: 'Account Type',
                                                prefixIcon: Icon(Icons.badge),
                                                border: OutlineInputBorder(),
                                              ),
                                              readOnly: true,
                                            ),
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              initialValue: _formatDate(user.createdAt),
                                              decoration: const InputDecoration(
                                                labelText: 'Member Since',
                                                prefixIcon: Icon(Icons.calendar_today),
                                                border: OutlineInputBorder(),
                                              ),
                                              readOnly: true,
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    controller: _nameController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Name',
                                                      prefixIcon: Icon(Icons.person),
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Please enter your name';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: TextFormField(
                                                    initialValue: user.email,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Email',
                                                      prefixIcon: Icon(Icons.email),
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    initialValue: user.isAdmin ? 'Admin' : 'Regular User',
                                                    decoration: const InputDecoration(
                                                      labelText: 'Account Type',
                                                      prefixIcon: Icon(Icons.badge),
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    readOnly: true,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: TextFormField(
                                                    initialValue: _formatDate(user.createdAt),
                                                    decoration: const InputDecoration(
                                                      labelText: 'Member Since',
                                                      prefixIcon: Icon(Icons.calendar_today),
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _updateProfile,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator()
                                          : Text((_selectedImage != null || _webImage != null)
                                              ? 'Update Profile & Upload Photo' 
                                              : 'Update Profile'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Account Stats
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Statistics',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem(context, 'Member Since', _formatDate(user.createdAt)),
                                _buildStatItem(context, 'Last Login', _formatDate(user.lastLogin)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Logout Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Show logout options dialog
                        final shouldClearRememberMe = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Do you want to clear your saved login information?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Keep Login Info'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear Login Info'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                        
                        if (shouldClearRememberMe != null) {
                          await Provider.of<AuthService>(context, listen: false)
                              .signOut(clearRememberedCredentials: shouldClearRememberMe);
                        }
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Remember Me Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Login Settings',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<Map<String, dynamic>>(
                              future: Provider.of<AuthService>(context, listen: false).getSavedCredentials(),
                              builder: (context, snapshot) {
                                final isRemembered = snapshot.data?['rememberMe'] ?? false;
                                
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isRemembered ? Icons.check_circle : Icons.cancel,
                                          color: isRemembered ? Colors.green : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isRemembered ? 'Remember Me: Enabled' : 'Remember Me: Disabled',
                                            style: TextStyle(
                                              color: isRemembered ? Colors.green : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isRemembered) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            try {
                                              await Provider.of<AuthService>(context, listen: false)
                                                  .clearSavedCredentials();
                                              setState(() {}); // Refresh the UI
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Remember me disabled. You will need to login again next time.'),
                                                  backgroundColor: Colors.orange,
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.clear),
                                          label: const Text('Disable Remember Me'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  ImageProvider? _getImageProvider(UserModel user) {
    // Show local preview first if available (during upload)
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_webImage != null) {
      return MemoryImage(_webImage!);
    } else if (user.photoUrl.isNotEmpty) {
      // Try to load from Firebase Storage, but handle CORS errors
      return NetworkImage(user.photoUrl);
    } else {
      return null;
    }
  }

  Widget _buildProfileImage(UserModel user) {
    // Show local preview first if available
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (_webImage != null) {
      return Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (user.photoUrl.isNotEmpty) {
      // Try to load from Firebase Storage with error handling
      return CachedNetworkImage(
        imageUrl: user.photoUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Center(
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(fontSize: 48, color: Colors.white),
          ),
        ),
      );
    } else {
      return Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: const TextStyle(fontSize: 48, color: Colors.white),
        ),
      );
    }
  }
} 