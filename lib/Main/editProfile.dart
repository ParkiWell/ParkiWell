import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../navbar.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_input.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final singleton = Singleton();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String image = "images/711128.png";
  final picker = ImagePicker();
  bool _isLoading = false;
  int _currentStep = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> updateImage() async {
    HapticUtils.lightImpact();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        image = pickedFile.path;
      });
      HapticUtils.success();
    }
  }

  Future<void> _createAccount() async {
    if (_nameController.text.trim().isEmpty) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticUtils.mediumImpact();

    try {
      singleton.setEmail(_emailController.text.trim().isEmpty
          ? 'Not provided'
          : _emailController.text.trim());
      singleton.setName(_nameController.text.trim());
      singleton.setImage(image);

      // Create user in local database
      final created =
          await singleton.createUser(_nameController.text.trim(), 0);
      if (!created) {
        throw Exception('Unable to create your account right now');
      }

      // Update image if custom image was selected
      if (image != "images/711128.png") {
        final updated = await singleton.updateUser(profileImage: image);
        if (!updated) {
          throw Exception('Unable to save your profile image');
        }
      }

      HapticUtils.success();

      if (singleton.firstTime && mounted) {
        singleton.setFirstTime(false);
        if (mounted) {
          // Navigate to main app
          unawaited(Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const Navbar()),
            (r) => false,
          ));
        }
      }
    } catch (e) {
      HapticUtils.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.error,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      HapticUtils.selectionClick();
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticUtils.selectionClick();
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Progress indicator
                  _buildProgressIndicator(colors),
                  const SizedBox(height: 32),

                  // Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildStepContent(colors, size),
                    ),
                  ),

                  // Navigation buttons
                  _buildNavigationButtons(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : colors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(AppColors colors, Size size) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(colors, size);
      case 1:
        return _buildProfileStep(colors);
      case 2:
        return _buildDetailsStep(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep(AppColors colors, Size size) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: size.height * 0.05),
          // App logo
          Image.asset(
            'images/logo.png',
            width: 140,
            height: 140,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 80,
                  color: colors.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Levio',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your personal companion for managing Parkinson\'s with care and precision.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          // Feature highlights
          _buildFeatureItem(
            colors,
            Icons.track_changes_rounded,
            'Track Symptoms',
            'Monitor and log your daily symptoms',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            colors,
            Icons.medication_rounded,
            'Medication Management',
            'Keep track of your medication schedule',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            colors,
            Icons.record_voice_over_rounded,
            'Speech Therapy',
            'Audio-guided exercises for voice clarity',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            colors,
            Icons.fitness_center_rounded,
            'Physical Exercises',
            'Video-guided workouts for mobility',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      AppColors colors, IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasCustomImage() {
    return image.isNotEmpty &&
        image != 'images/711128.png' &&
        !image.contains('711128');
  }

  Widget _buildProfileImage(double size, AppColors colors) {
    if (!_hasCustomImage()) {
      return _buildInitialsAvatar(size, colors);
    }

    if (image.startsWith('images/')) {
      return ClipOval(
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar(size, colors);
          },
        ),
      );
    } else {
      final file = File(image);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsAvatar(size, colors);
            },
          ),
        );
      }
      return _buildInitialsAvatar(size, colors);
    }
  }

  Widget _buildInitialsAvatar(double size, AppColors colors) {
    final displayName =
        _nameController.text.isNotEmpty ? _nameController.text : 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.2),
            colors.primaryLight.withValues(alpha: 0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStep(AppColors colors) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'Set up your profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo to personalize your account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 48),
          // Profile image picker
          GestureDetector(
            onTap: updateImage,
            child: Stack(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 3),
                  ),
                  child: _buildProfileImage(144, colors),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: colors.textOnPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tap to change photo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
          const SizedBox(height: 48),
          // Preview card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                _buildProfileImage(60, colors),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Preview',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                            ),
                      ),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Your Name'
                            : _nameController.text,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(AppColors colors) {
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Almost there!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Enter your details to complete setup',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 48),
          // Name field
          Text(
            'Name',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ModernTextField(
            controller: _nameController,
            hint: 'Enter your name',
            prefixIcon: Icons.person_outline_rounded,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
          // Email field
          Text(
            'Email (optional)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ModernTextField(
            controller: _emailController,
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),
          // Privacy note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: colors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your data is stored securely and will never be shared with third parties.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.info,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: ModernButton(
                text: 'Back',
                isOutlined: true,
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ModernButton(
              text: _currentStep == 2 ? 'Get Started' : 'Continue',
              isLoading: _isLoading,
              icon: _currentStep == 2
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: () {
                if (_currentStep == 2) {
                  _createAccount();
                } else {
                  _nextStep();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
