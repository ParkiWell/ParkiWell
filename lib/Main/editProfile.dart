import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../navbar.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
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
  final picker = ImagePicker();

  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  String image = 'images/711128.png';
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  int _step = 0;
  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  bool _isEmailValid(String email) {
    final value = email.trim();
    if (value.isEmpty) return true;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  bool _validateForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
      _emailError = _isEmailValid(email) ? null : 'Enter a valid email address';
    });

    return _nameError == null && _emailError == null;
  }

  Future<void> _createAccount() async {
    if (_isGoogleLoading) return;

    if (!_validateForm()) {
      HapticUtils.error();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();

      singleton.setEmail(email.isEmpty ? '[Email]' : email);
      singleton.setName(name);
      singleton.setImage(image);

      final created = await singleton.createUser(name, 0);
      if (!created) {
        throw Exception('Unable to create your account right now');
      }

      final userUpdated = await singleton.updateUser(
        userName: name,
        userEmail: email.isEmpty ? null : email,
        profileImage: image,
      );
      if (!userUpdated) {
        throw Exception('Unable to finish profile setup');
      }

      singleton.setFirstTime(false);

      if (!mounted) return;
      HapticUtils.success();

      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Navbar()),
        (route) => false,
      );
    } catch (e) {
      HapticUtils.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading || _isLoading) return;

    if (!singleton.isCloudConfigured) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Google sign-in requires cloud backend configuration.',
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _isGoogleLoading = true);
    HapticUtils.mediumImpact();

    try {
      final profile = await singleton.signInWithGoogle();
      if (profile == null) {
        throw Exception('Google sign-in was cancelled or could not complete.');
      }

      final fallbackFromEmail =
          profile.email != null && profile.email!.contains('@')
              ? profile.email!.split('@').first
              : 'Levio Member';
      final resolvedName =
          (profile.fullName != null && profile.fullName!.trim().isNotEmpty)
              ? profile.fullName!.trim()
              : (_nameController.text.trim().isNotEmpty
                  ? _nameController.text.trim()
                  : fallbackFromEmail);
      final resolvedEmail =
          (profile.email != null && profile.email!.trim().isNotEmpty)
              ? profile.email!.trim()
              : null;

      _nameController.text = resolvedName;
      if (resolvedEmail != null) {
        _emailController.text = resolvedEmail;
      }

      final synced = await singleton.createOrSyncAuthenticatedUser(
        displayName: resolvedName,
        userEmail: resolvedEmail,
        profileImage: image,
      );
      if (!synced) {
        throw Exception('Unable to complete account sync.');
      }

      singleton.setFirstTime(false);

      if (!mounted) return;
      HapticUtils.success();

      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Navbar()),
        (route) => false,
      );
    } catch (e) {
      HapticUtils.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign in failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _goToForm() {
    HapticUtils.selectionClick();
    setState(() => _step = 1);
  }

  void _goBack() {
    HapticUtils.selectionClick();
    setState(() => _step = 0);
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
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(size, colors),
        ),
      );
    }

    return ClipOval(
      child: Image.file(
        File(image),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _buildInitialsAvatar(size, colors),
      ),
    );
  }

  Widget _buildInitialsAvatar(double size, AppColors colors) {
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'U';
    final initial = displayName[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.2),
            colors.secondary.withValues(alpha: 0.14),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: FadeTransition(
        opacity: _fade,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(colors.background, colors.primaryLight, 0.1)!,
                colors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildTopBar(colors),
                  const SizedBox(height: 18),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _step == 0
                          ? _buildWelcomeStep(colors)
                          : _buildSignInStep(colors),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildBottomActions(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppColors colors) {
    return Row(
      children: [
        if (_step == 1)
          IconButton(
            onPressed: _goBack,
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: colors.surface.withValues(alpha: 0.8),
            ),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                _step == 0 ? 'Welcome' : 'Sign In',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final isActive = index <= _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive ? colors.primary : colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildWelcomeStep(AppColors colors) {
    return SingleChildScrollView(
      key: const ValueKey('welcome_step'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Sign in to Levio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your care space in under a minute. Your progress stays on-device, with secure cloud sync when configured.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          ModernCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Image.asset(
                      'images/logo.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.health_and_safety_rounded,
                        color: colors.primary,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalized, calm, and consistent',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Levio organizes symptoms, meds, speech, and movement in one place.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildBulletCard(
            colors,
            icon: Icons.shield_outlined,
            title: 'Private by default',
            subtitle:
                'Your profile data stays local unless cloud sync is enabled.',
          ),
          const SizedBox(height: 10),
          _buildBulletCard(
            colors,
            icon: Icons.track_changes_outlined,
            title: 'Actionable tracking',
            subtitle: 'Capture symptoms and routines for clearer patterns.',
          ),
          const SizedBox(height: 10),
          _buildBulletCard(
            colors,
            icon: Icons.favorite_outline,
            title: 'Supportive community',
            subtitle: 'Share safely with moderated posts and comments.',
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildBulletCard(
    AppColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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

  Widget _buildSignInStep(AppColors colors) {
    return SingleChildScrollView(
      key: const ValueKey('signin_step'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            'Finish your account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Continue with Google for one-tap sign in, or fill your details manually.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  (_isGoogleLoading || _isLoading) ? null : _signInWithGoogle,
              icon: _isGoogleLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    )
                  : Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                        ),
                      ),
                    ),
              label: Text(
                _isGoogleLoading
                    ? 'Connecting Google...'
                    : 'Continue with Google',
              ),
            ),
          ),
          if (!singleton.isCloudConfigured) ...[
            const SizedBox(height: 8),
            Text(
              'Google sign-in is available when cloud backend is configured.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: colors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'or continue manually',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Expanded(child: Divider(color: colors.border)),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: updateImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border, width: 3),
                    ),
                    child: _buildProfileImage(110, colors),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Tap to add profile photo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Name',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ModernTextField(
            controller: _nameController,
            hint: 'Enter your full name',
            prefixIcon: Icons.person_outline_rounded,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Email (optional)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ModernTextField(
            controller: _emailController,
            hint: 'you@example.com',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),
          const SizedBox(height: 16),
          ModernCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: singleton.isCloudConnected
                        ? colors.success.withValues(alpha: 0.12)
                        : colors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    singleton.isCloudConnected
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: singleton.isCloudConnected
                        ? colors.success
                        : colors.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        singleton.isCloudConnected
                            ? 'Backend connected'
                            : 'Running local-first',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        singleton.backendStatusDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ModernCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: colors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your data is encrypted on-device. Cloud sync uses an authenticated session when enabled.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppColors colors) {
    if (_step == 0) {
      return SizedBox(
        width: double.infinity,
        child: ModernButton(
          text: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _goToForm,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ModernButton(
            text: 'Back',
            isOutlined: true,
            onPressed: _goBack,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernButton(
            text: 'Sign In',
            icon: Icons.login_rounded,
            isLoading: _isLoading || _isGoogleLoading,
            onPressed: _createAccount,
          ),
        ),
      ],
    );
  }
}
