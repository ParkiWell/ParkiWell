import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../navbar.dart';
import '../services/cloud_backend_service.dart';
import '../services/tutorial_service.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/app_routes.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool startInSignIn;
  final VoidCallback? onBack;

  const EditProfileScreen({
    super.key,
    this.onComplete,
    this.startInSignIn = false,
    this.onBack,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

enum _AuthMode { signUp, signIn }

enum _EntryStage { auth, profileSetup }

class _EditProfileScreenState extends State<EditProfileScreen> {
  final singleton = Singleton();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  _AuthMode _mode = _AuthMode.signUp;
  _EntryStage _stage = _EntryStage.auth;
  int _modeTransitionDirection = 1;
  bool _isLoading = false;
  bool _replayTutorialAfterEntry = false;
  String _imagePath = 'images/711128.png';
  CloudAuthProfile? _pendingAuthProfile;

  @override
  void initState() {
    super.initState();
    _mode = widget.startInSignIn ? _AuthMode.signIn : _AuthMode.signUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _finishEntry() async {
    if (_replayTutorialAfterEntry) {
      await TutorialService().resetTutorial();
    }
    singleton.setFirstTime(false);
    singleton.setPage(0);
    HapticUtils.success();
    widget.onComplete?.call();
    if (!mounted || widget.onComplete != null) return;
    await Navigator.of(context).pushAndRemoveUntil(
      buildSubtleFadeRoute(page: const Navbar()),
      (route) => false,
    );
  }

  String _friendlyAuthMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('cancelled') || text.contains('canceled')) {
      return 'Sign in was cancelled.';
    }
    if (text.contains('invalid login') ||
        text.contains('invalid credentials') ||
        text.contains('wrong password')) {
      return 'Email or password is incorrect.';
    }
    if (text.contains('already registered') ||
        text.contains('already exists')) {
      return 'This email is already registered. Try signing in.';
    }
    if (text.contains('network') || text.contains('connection')) {
      return 'No internet connection. Please try again.';
    }
    if (text.contains('cloud') && text.contains('config')) {
      return 'Sign in is not available right now. Please try again later.';
    }
    return 'Authentication failed. Please try again.';
  }

  void _showError(String message) {
    if (!mounted) return;
    final colors = context.colors;
    HapticUtils.error();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: colors.surface.blend(colors.error, 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border.blend(colors.error, 0.58)),
          ),
        ),
      );
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    if (!singleton.isCloudConfigured) {
      _showError('Google sign in is not available right now.');
      return;
    }

    setState(() => _isLoading = true);
    HapticUtils.mediumImpact();
    try {
      final profile = await singleton.signInWithGoogle();
      if (profile == null) {
        throw Exception('Google sign in could not complete.');
      }

      final resolvedEmail = profile.email?.trim();
      final fallbackName =
          (resolvedEmail != null && resolvedEmail.contains('@'))
              ? resolvedEmail.split('@').first
              : 'User';
      final resolvedName =
          (profile.fullName != null && profile.fullName!.trim().isNotEmpty)
              ? profile.fullName!.trim()
              : fallbackName;

      if (_mode == _AuthMode.signIn) {
        final synced = await singleton.createOrSyncAuthenticatedUser(
          displayName: resolvedName,
          userEmail: resolvedEmail,
          profileImage: _imagePath,
        );
        if (!synced) {
          throw Exception('Unable to complete account sync.');
        }
        await _finishEntry();
        return;
      }

      _replayTutorialAfterEntry = true;
      _pendingAuthProfile = profile;
      _emailController.text = resolvedEmail ?? _emailController.text;
      final parts = resolvedName.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) _firstNameController.text = parts.first;
      if (parts.length > 1) {
        _lastNameController.text = parts.sublist(1).join(' ');
      }
      if (mounted) {
        setState(() => _stage = _EntryStage.profileSetup);
      }
    } catch (e) {
      _showError(_friendlyAuthMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueWithEmail() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!email.contains('@')) {
      _showError('Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (_mode == _AuthMode.signUp &&
        _confirmPasswordController.text != password) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    HapticUtils.mediumImpact();
    try {
      if (_mode == _AuthMode.signIn) {
        if (!singleton.isCloudConfigured) {
          _showError(
              'Sign in is not available right now. Please try again later.');
          return;
        }
        final profile = await singleton.signInWithEmailPassword(
          email: email,
          password: password,
        );
        if (profile == null) {
          _showError(
            _friendlyAuthMessage(
              singleton.lastCloudError ?? 'Sign in failed.',
            ),
          );
          return;
        }
        final displayName =
            (profile.fullName != null && profile.fullName!.trim().isNotEmpty)
                ? profile.fullName!.trim()
                : email.split('@').first;
        final synced = await singleton.createOrSyncAuthenticatedUser(
          displayName: displayName,
          userEmail: profile.email ?? email,
          profileImage: _imagePath,
        );
        if (!synced) {
          throw Exception('Unable to complete account sync.');
        }
        await _finishEntry();
        return;
      }

      // Sign up
      if (singleton.isCloudConfigured) {
        final profile = await singleton.signUpWithEmailPassword(
          email: email,
          password: password,
        );
        if (profile == null) {
          _showError(
            _friendlyAuthMessage(
              singleton.lastCloudError ?? 'Sign up failed.',
            ),
          );
          return;
        }
        _pendingAuthProfile = profile;
      } else {
        // No cloud: create account locally and go to profile setup
        _pendingAuthProfile = CloudAuthProfile(
          userId: '',
          email: email,
          fullName: null,
          avatarUrl: null,
        );
      }
      _replayTutorialAfterEntry = true;
      if (mounted) {
        setState(() => _stage = _EntryStage.profileSetup);
      }
    } catch (e) {
      _showError(_friendlyAuthMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    HapticUtils.lightImpact();
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || picked == null) return;
    setState(() => _imagePath = picked.path);
  }

  Future<void> _completeProfileSetup() async {
    if (_isLoading) return;
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty || last.isEmpty) {
      _showError('Enter both first and last name.');
      return;
    }

    final email = _pendingAuthProfile?.email?.trim().isNotEmpty == true
        ? _pendingAuthProfile!.email!.trim()
        : _emailController.text.trim();

    setState(() => _isLoading = true);
    HapticUtils.mediumImpact();
    try {
      final synced = singleton.isCloudConfigured
          ? await singleton.createOrSyncAuthenticatedUser(
              displayName: '$first $last',
              userEmail: email,
              profileImage: _imagePath,
            )
          : await singleton.createLocalOnlyUser(
              displayName: '$first $last',
              userEmail: email,
              profileImage: _imagePath,
            );
      if (!synced) {
        throw Exception('Unable to save your profile.');
      }
      await _finishEntry();
    } catch (e) {
      _showError(_friendlyAuthMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _initialsPreview() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fallback = _emailController.text.trim();
    final a =
        first.isNotEmpty ? first[0] : (fallback.isNotEmpty ? fallback[0] : 'U');
    final b = last.isNotEmpty ? last[0] : '';
    return '${a.toUpperCase()}${b.toUpperCase()}';
  }

  void _changeMode(_AuthMode nextMode) {
    if (_isLoading || _mode == nextMode) return;
    FocusScope.of(context).unfocus();
    HapticUtils.selectionClick();
    _modeTransitionDirection = nextMode.index > _mode.index ? 1 : -1;
    setState(() {
      _mode = nextMode;
      if (nextMode == _AuthMode.signIn) {
        _replayTutorialAfterEntry = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background.blend(colors.primaryLight, 0.18),
              colors.background.blend(colors.secondaryLight, 0.07),
              colors.background,
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: _stage == _EntryStage.auth
                ? _buildAuthStage(colors)
                : _buildProfileSetupStage(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStage(AppColors colors) {
    final cloudReady = singleton.isCloudConfigured;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (widget.onBack != null)
                    _buildTopActionButton(
                      colors: colors,
                      icon: Icons.arrow_back_rounded,
                      onTap: widget.onBack!,
                    )
                  else
                    const SizedBox(width: 44, height: 44),
                ],
              ),
              const SizedBox(height: 20),
              _buildModeAnimatedSwitcher(
                child: Column(
                  key: ValueKey<String>('auth-copy-${_mode.name}'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _mode == _AuthMode.signUp
                          ? 'Create your account'
                          : 'Welcome back',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mode == _AuthMode.signUp
                          ? 'Sign up with email to get started.'
                          : 'Sign in to continue where you left off.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AutofillGroup(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildModeSelector(colors),
                        const SizedBox(height: 20),
                        _buildFieldLabel('Email'),
                        _buildInputField(
                          controller: _emailController,
                          hintText: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 14),
                        _buildFieldLabel('Password'),
                        _buildInputField(
                          controller: _passwordController,
                          hintText: _mode == _AuthMode.signUp
                              ? 'At least 6 characters'
                              : 'Enter your password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                        ),
                        ClipRect(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: _mode == _AuthMode.signUp
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 14),
                                      _buildFieldLabel('Confirm Password'),
                                      _buildInputField(
                                        controller: _confirmPasswordController,
                                        hintText: 'Retype your password',
                                        icon: Icons.verified_user_outlined,
                                        obscureText: true,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _continueWithEmail,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.textOnPrimary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 18,
                                  ),
                            label: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              layoutBuilder: (currentChild, previousChildren) {
                                return ClipRect(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child:
                                        currentChild ?? const SizedBox.shrink(),
                                  ),
                                );
                              },
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(
                                      _modeTransitionDirection * 0.02,
                                      0,
                                    ),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                _isLoading
                                    ? 'Please wait...'
                                    : _mode == _AuthMode.signUp
                                        ? 'Continue with Email'
                                        : 'Sign In with Email',
                                key: ValueKey<String>(
                                  'email-cta-${_mode.name}-$_isLoading',
                                ),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              elevation: 0,
                              backgroundColor: colors.primaryDark.blend(
                                colors.primary,
                                0.22,
                              ),
                              foregroundColor: colors.textOnPrimary,
                              disabledBackgroundColor:
                                  colors.surface.blend(colors.primary, 0.16),
                              disabledForegroundColor:
                                  colors.textSecondary.blend(
                                colors.surface,
                                0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        if (cloudReady) ...[
                          const SizedBox(height: 12),
                          _buildGoogleButton(colors),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeAnimatedSwitcher({required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: currentChild ?? const SizedBox.shrink(),
          ),
        );
      },
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_modeTransitionDirection * 0.03, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildTopActionButton({
    required AppColors colors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: colors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildModeSelector(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final segmentWidth = (constraints.maxWidth - gap) / 2;

          return SizedBox(
            height: 52,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: _mode == _AuthMode.signUp ? 0 : segmentWidth + gap,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.border.blend(colors.primary, 0.52),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        colors: colors,
                        label: 'Sign Up',
                        selected: _mode == _AuthMode.signUp,
                        onTap: () => _changeMode(_AuthMode.signUp),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: _buildModeTab(
                        colors: colors,
                        label: 'Sign In',
                        selected: _mode == _AuthMode.signIn,
                        onTap: () => _changeMode(_AuthMode.signIn),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeTab({
    required AppColors colors,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? colors.primary : colors.textSecondary,
                ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<String>? autofillHints,
    ValueChanged<String>? onChanged,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20, color: colors.textTertiary),
        fillColor: colors.surface.blend(colors.background, 0.4),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AppColors colors) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.surface,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Text(
                'G',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF4285F4),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _mode == _AuthMode.signUp
                  ? 'Continue with Google'
                  : 'Sign In with Google',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSetupStage(AppColors colors) {
    final hasCustomImage = _imagePath.isNotEmpty &&
        !_imagePath.contains('711128') &&
        !_imagePath.startsWith('images/');
    final emailSummary = _pendingAuthProfile?.email?.trim().isNotEmpty == true
        ? _pendingAuthProfile!.email!.trim()
        : _emailController.text.trim();

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _buildTopActionButton(
                    colors: colors,
                    icon: Icons.arrow_back_rounded,
                    onTap: () => setState(() => _stage = _EntryStage.auth),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatarPreview(colors, hasCustomImage),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set up your profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add your name and a photo so your care space feels like yours.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                              if (emailSummary.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Text(
                                    emailSummary,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _pickProfileImage,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: const Text('Choose profile picture'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colors.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildFieldLabel('First Name'),
                    _buildInputField(
                      controller: _firstNameController,
                      hintText: 'First name',
                      icon: Icons.person_outline_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _buildFieldLabel('Last Name'),
                    _buildInputField(
                      controller: _lastNameController,
                      hintText: 'Last name',
                      icon: Icons.badge_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(
                        text: _isLoading ? 'Saving...' : 'Finish Setup',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        backgroundColor:
                            colors.primaryDark.blend(colors.primary, 0.22),
                        onPressed: _completeProfileSetup,
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
  }

  Widget _buildAvatarPreview(AppColors colors, bool hasCustomImage) {
    return GestureDetector(
      onTap: _isLoading ? null : _pickProfileImage,
      child: Container(
        width: 94,
        height: 94,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.border, width: 1.5),
          color: colors.surfaceVariant,
        ),
        child: ClipOval(
          child: hasCustomImage
              ? Image.file(
                  File(_imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildAvatarFallback(colors),
                )
              : _buildAvatarFallback(colors),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(AppColors colors) {
    return Center(
      child: Text(
        _initialsPreview(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
      ),
    );
  }
}
