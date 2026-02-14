import 'package:flutter/material.dart';
import 'dart:io';

import 'Main/home.dart';
import 'Main/manage.dart';
import 'Main/recovery.dart';
import 'Main/community.dart';
import 'Main/profile.dart';
import 'services/tutorial_service.dart';
import 'singleton.dart';
import 'theme/app_theme.dart';
import 'utils/haptic_utils.dart';
import 'widgets/modern_input.dart';
import 'widgets/tutorial_overlay.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> with TickerProviderStateMixin {
  final singleton = Singleton();
  final tutorialService = TutorialService();
  int currentIndex = 0;
  bool button = false;
  bool addPost = false;
  bool editProfile = false;
  IconData iconButton = Icons.edit_outlined;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late final List<TutorialStep> _tutorialSteps;

  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _avatarKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _exerciseCardKey = GlobalKey();
  final GlobalKey _addMedicationKey = GlobalKey();
  final List<GlobalKey> _navItemKeys =
      List<GlobalKey>.generate(5, (_) => GlobalKey());

  late final List<Widget> _tabs = [
    const HomeScreen(),
    ManageScreen(addMedicationKey: _addMedicationKey),
    RecoveryScreen(exerciseCardKey: _exerciseCardKey),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Manage'),
    _NavItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Recovery'),
    _NavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Community'),
    _NavItem(
        icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  void checkTab() {
    if (currentIndex == 4) {
      button = true;
      addPost = false;
      editProfile = true;
      iconButton = Icons.edit;
    } else {
      button = false;
      addPost = false;
      editProfile = false;
    }
  }

  @override
  void initState() {
    super.initState();
    currentIndex = singleton.page;
    singleton.addListener(_onSingletonPageChange);
    if (currentIndex == 3 || currentIndex == 4) checkTab();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      ),
    );
    if (button) {
      _fabAnimationController.forward();
    }

    _tutorialSteps = _buildTutorialSteps();
  }

  @override
  void dispose() {
    singleton.removeListener(_onSingletonPageChange);
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> updateAccount({
    required String rawName,
    required String rawEmail,
  }) async {
    final updatedName =
        rawName.trim().isEmpty ? singleton.name : rawName.trim();
    final updatedEmail =
        rawEmail.trim().isEmpty ? singleton.email : rawEmail.trim();

    singleton.setEmail(updatedEmail);
    singleton.setName(updatedName);

    final updated = await singleton.updateUser(
      userName: updatedName,
      userEmail: updatedEmail,
    );
    if (!updated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to update profile right now'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onTabTapped(int index) {
    HapticUtils.selectionClick();
    setState(() {
      currentIndex = index;
      singleton.setPage(index);
      button = false;
      if (currentIndex == 3 || currentIndex == 4) {
        checkTab();
        _fabAnimationController.forward(from: 0);
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _switchTabForTutorial(int index) {
    if (!mounted) return;
    if (currentIndex == index) return;

    setState(() {
      currentIndex = index;
      singleton.setPage(index);
      button = false;
      if (currentIndex == 3 || currentIndex == 4) {
        checkTab();
        _fabAnimationController.forward(from: 0);
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _onSingletonPageChange() {
    if (!mounted) return;
    final targetIndex = singleton.page;
    setState(() {
      if (targetIndex != currentIndex) {
        currentIndex = targetIndex;
        button = false;
        if (currentIndex == 3 || currentIndex == 4) {
          checkTab();
          _fabAnimationController.forward(from: 0);
        } else {
          _fabAnimationController.reverse();
        }
      }
    });
  }

  List<TutorialStep> _buildTutorialSteps() {
    return <TutorialStep>[
      TutorialStep(
        targetKey: _navItemKeys[0],
        title: 'Home Dashboard',
        description:
            'Your home for symptom and medication trends. Use the buttons below to log a symptom or add a medication.',
        onStepStarted: () => _switchTabForTutorial(0),
      ),
      TutorialStep(
        targetKey: _navItemKeys[1],
        title: 'Manage',
        description:
            'Manage is where you log symptoms and add medication schedules. Quick actions are right here.',
        onStepStarted: () => _switchTabForTutorial(1),
      ),
      TutorialStep(
        targetKey: _addMedicationKey,
        title: 'Log a medication',
        description:
            'Tap Add Medication to create a schedule. Enter the name, pick days (e.g. Everyday or Weekdays), and save.',
        onStepStarted: () => _switchTabForTutorial(1),
      ),
      TutorialStep(
        targetKey: _navItemKeys[2],
        title: 'Recovery',
        description:
            'Recovery has guided speech and exercise videos. Tap the tab to open it.',
        onStepStarted: () => _switchTabForTutorial(2),
      ),
      TutorialStep(
        targetKey: _exerciseCardKey,
        title: 'Watch a video',
        description:
            'Tap Physical Exercises to open the list, then tap any exercise to watch the video. Use the back button when you\'re done.',
        onStepStarted: () => _switchTabForTutorial(2),
      ),
      TutorialStep(
        targetKey: _navItemKeys[3],
        title: 'Community',
        description:
            'Share and read posts in the community feed. Tap Feed or Resources in the tabs.',
        onStepStarted: () => _switchTabForTutorial(3),
      ),
      TutorialStep(
        targetKey: _navItemKeys[4],
        title: 'Profile',
        description:
            'Your profile and progress summary. Tap the tab to open it.',
        onStepStarted: () => _switchTabForTutorial(4),
      ),
      TutorialStep(
        targetKey: _avatarKey,
        title: 'Quick Profile',
        description: 'Tap your avatar anytime to jump to profile.',
        onStepStarted: () => _switchTabForTutorial(4),
        tooltipPosition: TutorialTooltipPosition.above,
      ),
      TutorialStep(
        targetKey: _settingsKey,
        title: 'Settings',
        description: 'Theme, legal docs, replay this tutorial, or sign out.',
        onStepStarted: () => _switchTabForTutorial(4),
        tooltipPosition: TutorialTooltipPosition.above,
      ),
      TutorialStep(
        targetKey: _fabKey,
        title: 'Quick Edit',
        description: 'On Profile, this button opens edit profile.',
        onStepStarted: () => _switchTabForTutorial(4),
        tooltipPosition: TutorialTooltipPosition.above,
      ),
    ];
  }

  bool _hasCustomImage() {
    return singleton.image.isNotEmpty &&
        singleton.image != 'images/711128.png' &&
        !singleton.image.contains('711128');
  }

  Widget _buildNavbarAvatar(AppColors colors) {
    if (_hasCustomImage()) {
      if (singleton.image.startsWith('images/')) {
        return Image.asset(
          singleton.image,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(colors),
        );
      }
      return Image.file(
        File(singleton.image),
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        errorBuilder: (_, __, ___) => _buildInitialsAvatar(colors),
      );
    }
    return _buildInitialsAvatar(colors);
  }

  Widget _buildInitialsAvatar(AppColors colors) {
    final displayName = singleton.name != '[Name]' && singleton.name.isNotEmpty
        ? singleton.name
        : 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      width: 36,
      height: 36,
      color: colors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final colors = context.colors;
    final nameController = TextEditingController(
      text: singleton.name == '[Name]' ? '' : singleton.name,
    );
    final emailController = TextEditingController(
      text: singleton.email == '[Email]' ? '' : singleton.email,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext c) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(c).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Edit Profile',
                  style: Theme.of(c).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: nameController,
                  label: 'Name',
                  hint: 'Enter your name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                ModernTextField(
                  controller: emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticUtils.lightImpact();
                          Navigator.pop(c);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: colors.border),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticUtils.lightImpact();
                          await updateAccount(
                            rawName: nameController.text,
                            rawEmail: emailController.text,
                          );
                          if (!mounted || !c.mounted) return;
                          Navigator.pop(c);
                          await Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (r) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TutorialOverlay(
      steps: _tutorialSteps,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colors.background,
        appBar: _buildAppBar(colors),
        body: Column(
          children: [
            if (singleton.isCloudConfigured && !singleton.isOnline)
              _buildConnectionBanner(colors),
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: _tabs,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(colors),
        floatingActionButton: _buildFAB(colors),
      ),
    );
  }

  Widget _buildConnectionBanner(AppColors colors) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: colors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode: showing local data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppColors colors) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.background,
      toolbarHeight: 46,
      leadingWidth: 180,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: [
            Container(
              key: _titleKey,
              child: Text(
                navItems[currentIndex].label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // User avatar
        GestureDetector(
          onTap: () => _onTabTapped(4),
          child: Container(
            key: _avatarKey,
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: currentIndex == 4 ? colors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: _buildNavbarAvatar(colors),
            ),
          ),
        ),
        IconButton(
          key: _settingsKey,
          iconSize: 19,
          icon: Icon(
            Icons.settings_outlined,
            color: colors.textSecondary,
          ),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pushNamed(context, '/settingsScreen');
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNavBar(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top:
              BorderSide(color: colors.border.withValues(alpha: 0.8), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = currentIndex == index;
              return _buildNavItem(
                navItems[index],
                isSelected,
                colors,
                _navItemKeys[index],
                () => _onTabTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    _NavItem item,
    bool isSelected,
    AppColors colors,
    GlobalKey itemKey,
    VoidCallback onTap,
  ) {
    return KeyedSubtree(
      key: itemKey,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? colors.primary : colors.navUnselected,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected ? colors.primary : colors.navUnselected,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFAB(AppColors colors) {
    if (!button) return null;

    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton(
        key: _fabKey,
        onPressed: () {
          HapticUtils.lightImpact();
          if (addPost) {
            // Add post functionality
          }
          if (editProfile) {
            _showEditProfileDialog();
          }
        },
        elevation: 2,
        child: Icon(iconButton, size: 22),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
