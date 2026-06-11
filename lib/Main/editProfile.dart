import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

import '../services/cloud_backend_service.dart';
import '../services/tutorial_service.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
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

enum _EntryStage { auth, profileSetup, goals }

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
  final int _modeTransitionDirection = 1;
  bool _isLoading = false;
  bool _replayTutorialAfterEntry = false;
  bool _awaitingEmailVerification = false;
  int _speechGoal = 4;
  int _physicalGoal = 4;
  String _imagePath = 'images/711128.png';
  CloudAuthProfile? _pendingAuthProfile;
  StreamSubscription<CloudAuthProfile>? _verifiedSignInSubscription;

  @override
  void initState() {
    super.initState();
    _mode = widget.startInSignIn ? _AuthMode.signIn : _AuthMode.signUp;
    _stage = widget.startInSignIn ? _EntryStage.auth : _EntryStage.profileSetup;
    _speechGoal = singleton.weeklySpeechExerciseGoal;
    _physicalGoal = singleton.weeklyPhysicalExerciseGoal;
    if (singleton.isCloudConfigured) {
      _verifiedSignInSubscription =
          singleton.cloudVerifiedSignIns.listen(_onVerifiedSignIn);
    }
  }

  void _onVerifiedSignIn(CloudAuthProfile profile) {
    if (!mounted || !_awaitingEmailVerification) return;
    _awaitingEmailVerification = false;
    HapticUtils.success();
    final email = profile.email?.trim();
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
    setState(() {
      _pendingAuthProfile = profile;
      _replayTutorialAfterEntry = true;
      _isLoading = true;
    });
    final colors = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          content: Text(
            'Email verified! Finishing setup.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: colors.surface.blend(colors.success, 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border.blend(colors.success, 0.58)),
          ),
        ),
      );
    _finishVerifiedEmailSetup();
  }

  @override
  void dispose() {
    _verifiedSignInSubscription?.cancel();
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
    // Never push a second Navbar over the app root; the root already hosts
    // it and duplicate trees collide on GlobalKeys.
    Navigator.of(context).popUntil((route) => route.isFirst);
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
    if (text.contains('verification link') ||
        text.contains('check your email') ||
        text.contains('email confirmation')) {
      return 'Check your email for a verification link, then sign in.';
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

      if (!mounted) return;
      _replayTutorialAfterEntry = true;
      _pendingAuthProfile = profile;
      _emailController.text = resolvedEmail ?? _emailController.text;
      await _saveProfileAndFinish();
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
          final error = singleton.lastCloudError ?? 'Sign up failed.';
          _awaitingEmailVerification =
              error.toLowerCase().contains('verification link');
          _showError(_friendlyAuthMessage(error));
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
      await _saveProfileAndFinish();
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

  void _continueFromProfileSetup() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty || last.isEmpty) {
      _showError('Enter both first and last name.');
      return;
    }

    HapticUtils.selectionClick();
    setState(() => _stage = _EntryStage.goals);
  }

  void _continueFromGoals() {
    singleton.setTherapyGoals(
      weeklySpeech: _speechGoal,
      weeklyPhysical: _physicalGoal,
    );
    HapticUtils.selectionClick();
    setState(() => _stage = _EntryStage.auth);
  }

  Future<void> _saveProfileAndFinish() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty || last.isEmpty) {
      throw Exception('Enter both first and last name.');
    }

    final email = _pendingAuthProfile?.email?.trim().isNotEmpty == true
        ? _pendingAuthProfile!.email!.trim()
        : _emailController.text.trim();

    singleton.setTherapyGoals(
      weeklySpeech: _speechGoal,
      weeklyPhysical: _physicalGoal,
    );

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
  }

  Future<void> _finishVerifiedEmailSetup() async {
    try {
      await _saveProfileAndFinish();
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: switch (_stage) {
                _EntryStage.auth => KeyedSubtree(
                    key: const ValueKey<String>('stage-auth'),
                    child: _buildAuthStage(colors),
                  ),
                _EntryStage.profileSetup => KeyedSubtree(
                    key: const ValueKey<String>('stage-profile'),
                    child: _buildProfileSetupStage(colors),
                  ),
                _EntryStage.goals => KeyedSubtree(
                    key: const ValueKey<String>('stage-goals'),
                    child: _buildGoalsStage(colors),
                  ),
              },
            ),
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
                      onTap: () {
                        if (_mode == _AuthMode.signUp) {
                          setState(() => _stage = _EntryStage.goals);
                        } else {
                          widget.onBack!();
                        }
                      },
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
                          ? 'Add an email and password to save your profile and therapy goals.'
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
                                        ? 'Create Account'
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
                  ? 'Create with Google'
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
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        setState(() => _stage = _EntryStage.auth);
                      }
                    },
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
                                'Add your name and a photo before choosing your therapy goals.',
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
                        text: 'Continue to Goals',
                        icon: Icons.arrow_forward_rounded,
                        backgroundColor:
                            colors.primaryDark.blend(colors.primary, 0.22),
                        onPressed: _continueFromProfileSetup,
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

  Widget _buildGoalsStage(AppColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
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
                    onTap: () =>
                        setState(() => _stage = _EntryStage.profileSetup),
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
                    Text(
                      'Set therapy goals',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how many speech and physical exercises you want to do each week. You can change this later in Recovery.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 22),
                    _GoalSetupRow(
                      colors: colors,
                      icon: Icons.record_voice_over_rounded,
                      title: 'Speech exercises',
                      subtitle: 'Voice, clarity, and breath practice',
                      accent: colors.primary,
                      value: _speechGoal,
                      onDecrease: () => setState(
                        () => _speechGoal =
                            (_speechGoal - 1).clamp(0, 99).toInt(),
                      ),
                      onIncrease: () => setState(
                        () => _speechGoal =
                            (_speechGoal + 1).clamp(0, 99).toInt(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _GoalSetupRow(
                      colors: colors,
                      icon: Icons.fitness_center_rounded,
                      title: 'Physical exercises',
                      subtitle: 'Mobility, balance, and strength sessions',
                      accent: colors.secondary,
                      value: _physicalGoal,
                      onDecrease: () => setState(
                        () => _physicalGoal =
                            (_physicalGoal - 1).clamp(0, 99).toInt(),
                      ),
                      onIncrease: () => setState(
                        () => _physicalGoal =
                            (_physicalGoal + 1).clamp(0, 99).toInt(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(
                        text: 'Continue to Account',
                        icon: Icons.arrow_forward_rounded,
                        backgroundColor:
                            colors.primaryDark.blend(colors.primary, 0.22),
                        onPressed: _continueFromGoals,
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

class _GoalSetupRow extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _GoalSetupRow({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _GoalSetupButton(
            colors: colors,
            icon: Icons.remove_rounded,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 42,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          _GoalSetupButton(
            colors: colors,
            icon: Icons.add_rounded,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _GoalSetupButton extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final VoidCallback onTap;

  const _GoalSetupButton({
    required this.colors,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.selectionClick();
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 18, color: colors.textPrimary),
      ),
    );
  }
}
