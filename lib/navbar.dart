import 'package:flutter/material.dart';
import 'package:levio/linechart.dart';
import 'dart:io';

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
  final List<GlobalKey> _navItemKeys =
      List<GlobalKey>.generate(5, (_) => GlobalKey());

  final List<Widget> tabs = [
    const LineChartSample1(),
    const ManageScreen(),
    const RecoveryScreen(),
    const CommunityScreen(),
    const ProfileScreen()
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
    if (targetIndex == currentIndex) return;

    setState(() {
      currentIndex = targetIndex;
      button = false;
      if (currentIndex == 3 || currentIndex == 4) {
        checkTab();
        _fabAnimationController.forward(from: 0);
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  List<TutorialStep> _buildTutorialSteps() {
    return <TutorialStep>[
      TutorialStep(
        targetKey: _navItemKeys[0],
        title: 'Home Dashboard',
        description:
            'This is your home dashboard for symptom and medication trend snapshots.',
        onStepStarted: () => _switchTabForTutorial(0),
      ),
      TutorialStep(
        targetKey: _navItemKeys[1],
        title: 'Manage',
        description:
            'Use Manage to log symptoms, add medication schedules, and review care activity.',
        onStepStarted: () => _switchTabForTutorial(1),
      ),
      TutorialStep(
        targetKey: _navItemKeys[2],
        title: 'Recovery',
        description:
            'Recovery gives you guided speech, movement, and exercise sessions.',
        onStepStarted: () => _switchTabForTutorial(2),
      ),
      TutorialStep(
        targetKey: _navItemKeys[3],
        title: 'Community',
        description:
            'Community lets you connect with peers, groups, and trusted external resources.',
        onStepStarted: () => _switchTabForTutorial(3),
      ),
      TutorialStep(
        targetKey: _navItemKeys[4],
        title: 'Profile',
        description:
            'Profile keeps your account and progress summary in one place.',
        onStepStarted: () => _switchTabForTutorial(4),
      ),
      TutorialStep(
        targetKey: _avatarKey,
        title: 'Quick Profile',
        description:
            'Tap your avatar to jump to profile from anywhere in the app.',
        onStepStarted: () => _switchTabForTutorial(4),
        tooltipPosition: TutorialTooltipPosition.above,
      ),
      TutorialStep(
        targetKey: _settingsKey,
        title: 'Settings',
        description:
            'Open Settings to change theme, review legal docs, replay tutorial, or sign out.',
        onStepStarted: () => _switchTabForTutorial(4),
        tooltipPosition: TutorialTooltipPosition.above,
      ),
      TutorialStep(
        targetKey: _fabKey,
        title: 'Quick Edit',
        description:
            'Use this quick edit button to update your profile details.',
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
        appBar: _buildAppBar(colors),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Container(
            key: ValueKey(currentIndex),
            child: tabs[currentIndex],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(colors),
        floatingActionButton: _buildFAB(colors),
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
        color: colors.navBackground,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
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
