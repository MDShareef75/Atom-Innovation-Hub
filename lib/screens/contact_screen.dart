import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:atoms_innovation_hub/services/contact_service.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _contactInfo;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
    _prefillUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadContactInfo() async {
    try {
      final contactService = Provider.of<ContactService>(context, listen: false);
      await contactService.initializeContactInfo();
      final contactInfo = await contactService.getContactInfo();
      setState(() {
        _contactInfo = contactInfo;
      });
    } catch (e) {
      print('Error loading contact info: $e');
    }
  }

  Future<void> _prefillUserInfo() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      try {
        final userModel = await authService.userModelStream(user.uid).first;
        if (userModel != null) {
          setState(() {
            _nameController.text = userModel.name;
            _emailController.text = userModel.email;
            _phoneController.text = userModel.phoneNumber;
          });
        }
      } catch (e) {
        print('Error loading user info: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final contactService = Provider.of<ContactService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        
        await contactService.sendContactMessage(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          userId: authService.currentUser?.uid,
        );

        // Clear only subject and message, keep user info populated
        _subjectController.clear();
        _messageController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully! We\'ll get back to you soon.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

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
                      Icons.contact_mail,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Contact Us',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'d love to hear from you. Send us a message!',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;
                
                if (isMobile) {
                  return Column(
                    children: [
                      // Contact Information
                      Column(
                        children: [
                          _buildContactCard(
                            context,
                            'Email',
                            _contactInfo?['email'] ?? 'atom.innovatex@gmail.com',
                            Icons.email,
                            () => _launchUrl('mailto:${_contactInfo?['email'] ?? 'atom.innovatex@gmail.com'}'),
                          ),
                          const SizedBox(height: 16),
                          _buildContactCard(
                            context,
                            'Phone',
                            _contactInfo?['phone'] ?? '+91 9945546164',
                            Icons.phone,
                            () => _launchUrl('tel:${(_contactInfo?['phone'] ?? '+91 9945546164').replaceAll(' ', '')}'),
                          ),
                          const SizedBox(height: 16),
                          _buildContactCard(
                            context,
                            'Address',
                            _contactInfo?['address'] ?? 'Chikmagalur, Karnataka\nIndia',
                            Icons.location_on,
                            null,
                          ),
                          const SizedBox(height: 16),
                          _buildSocialLinks(context),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Contact Form
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send us a Message',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Mobile: Stack form fields vertically
                                Column(
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Your Name',
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
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Your Email',
                                        prefixIcon: Icon(Icons.email),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Your Phone',
                                        prefixIcon: Icon(Icons.phone),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                TextFormField(
                                  controller: _subjectController,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject',
                                    prefixIcon: Icon(Icons.subject),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a subject';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                TextFormField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Your Message',
                                    prefixIcon: Icon(Icons.message),
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 5,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your message';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 24),
                                
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendMessage,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(16),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : const Text('Send Message'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact Information
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildContactCard(
                              context,
                              'Email',
                              _contactInfo?['email'] ?? 'atom.innovatex@gmail.com',
                              Icons.email,
                              () => _launchUrl('mailto:${_contactInfo?['email'] ?? 'atom.innovatex@gmail.com'}'),
                            ),
                            const SizedBox(height: 16),
                            _buildContactCard(
                              context,
                              'Phone',
                              _contactInfo?['phone'] ?? '+91 9945546164',
                              Icons.phone,
                              () => _launchUrl('tel:${(_contactInfo?['phone'] ?? '+91 9945546164').replaceAll(' ', '')}'),
                            ),
                            const SizedBox(height: 16),
                            _buildContactCard(
                              context,
                              'Address',
                              _contactInfo?['address'] ?? 'Chikmagalur, Karnataka\nIndia',
                              Icons.location_on,
                              null,
                            ),
                            const SizedBox(height: 16),
                            _buildSocialLinks(context),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 24),
                      
                      // Contact Form
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Send us a Message',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Your Name',
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
                                          controller: _emailController,
                                          decoration: const InputDecoration(
                                            labelText: 'Your Email',
                                            prefixIcon: Icon(Icons.email),
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!value.contains('@')) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Your Phone',
                                      prefixIcon: Icon(Icons.phone),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your phone';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  TextFormField(
                                    controller: _subjectController,
                                    decoration: const InputDecoration(
                                      labelText: 'Subject',
                                      prefixIcon: Icon(Icons.subject),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a subject';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  TextFormField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Your Message',
                                      prefixIcon: Icon(Icons.message),
                                      border: OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                    ),
                                    maxLines: 5,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your message';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _sendMessage,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator()
                                          : const Text('Send Message'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 32),
            
            // FAQ Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFAQItem(
                      context,
                      'How can I submit my app to the platform?',
                      'You can submit your app through the admin panel if you have admin access, or contact us directly.',
                    ),
                    _buildFAQItem(
                      context,
                      'Can I write blog posts for the platform?',
                      'Yes! Contact us to discuss becoming a contributor to our blog.',
                    ),
                    _buildFAQItem(
                      context,
                      'How do I report a bug or issue?',
                      'Please use the contact form above or email us directly with details about the issue.',
                    ),
                    _buildFAQItem(
                      context,
                      'Is the platform open source?',
                      'Currently, this is a private project, but we may consider open-sourcing parts of it in the future.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLinks(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow Us',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialButton(
                  Icons.language,
                  'Website',
                  () => _launchUrl('https://atomshub.com'),
                ),
                _buildSocialButton(
                  Icons.code,
                  'GitHub',
                  () => _launchUrl('https://github.com/atomshub'),
                ),
                _buildSocialButton(
                  Icons.work,
                  'LinkedIn',
                  () => _launchUrl('https://linkedin.com/company/atomshub'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
} 