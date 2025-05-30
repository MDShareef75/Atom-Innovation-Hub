import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:atoms_innovation_hub/providers/theme_provider.dart';

class ThemeSwitchWidget extends StatelessWidget {
  final bool showLabel;
  final double width;
  final double height;
  
  const ThemeSwitchWidget({
    super.key,
    this.showLabel = true,
    this.width = 60,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabel) ...[
              Icon(
                Icons.light_mode,
                size: 20,
                color: !themeProvider.isDarkMode 
                    ? Colors.orange 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
            ],
            
            GestureDetector(
              onTap: () async {
                await themeProvider.toggleTheme();
                
                // Haptic feedback
                if (Theme.of(context).platform == TargetPlatform.iOS ||
                    Theme.of(context).platform == TargetPlatform.android) {
                  // Add haptic feedback for mobile
                }
                
                // Show feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${themeProvider.isDarkMode ? 'Dark' : 'Light'} mode enabled',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 1500),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode
                        ? [const Color(0xFF2D3748), const Color(0xFF1A202C)]
                        : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E0)],
                  ),
                  border: Border.all(
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF4A5568)
                        : const Color(0xFFA0AEC0),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background icons
                    Positioned(
                      left: 6,
                      top: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: !themeProvider.isDarkMode ? 1.0 : 0.3,
                        child: Icon(
                          Icons.light_mode,
                          size: height * 0.6,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: themeProvider.isDarkMode ? 1.0 : 0.3,
                        child: Icon(
                          Icons.dark_mode,
                          size: height * 0.6,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    
                    // Sliding toggle
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: themeProvider.isDarkMode ? width - height + 2 : 2,
                      top: 2,
                      child: Container(
                        width: height - 4,
                        height: height - 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: themeProvider.isDarkMode
                                ? [Colors.indigo, Colors.indigo.shade700]
                                : [Colors.orange, Colors.orange.shade700],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (themeProvider.isDarkMode ? Colors.indigo : Colors.orange)
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 4,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Icon(
                          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.white,
                          size: height * 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (showLabel) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.dark_mode,
                size: 20,
                color: themeProvider.isDarkMode 
                    ? Colors.indigo 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ],
        );
      },
    );
  }
} 