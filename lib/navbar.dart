import 'package:flutter/material.dart';
import 'dart:io';

import 'Recovery/exercise.dart';
import 'Main/home.dart';
import 'Main/manage.dart';
import 'Main/recovery.dart';
import 'Main/community.dart';
import 'Main/profile.dart';
import 'Manage/schedule.dart';
import 'services/tutorial_targets.dart';
import 'services/tutorial_service.dart';
import 'singleton.dart';
import 'theme/app_theme.dart';
import 'utils/app_routes.dart';
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
  int _previousIndex = 0;
  bool _tabTransitionMovesForward = true;
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
  final List<GlobalKey> _navItemKeys =
      List<GlobalKey>.generate(5, (_) => GlobalKey());

  late final List<Widget> _tabs = [
    const HomeScreen(),
    const ManageScreen(),
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
    _previousIndex = currentIndex;
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
    _setCurrentIndex(index, syncSingleton: true);
  }

  void _switchTabForTutorial(int index) {
    if (!mounted) return;
    _setCurrentIndex(index, syncSingleton: true);
  }

  void _onSingletonPageChange() {
    if (!mounted) return;
    final targetIndex = singleton.page;
    _setCurrentIndex(targetIndex, syncSingleton: false);
  }

  void _setCurrentIndex(int index, {required bool syncSingleton}) {
    if (index == currentIndex) return;

    setState(() {
      _previousIndex = currentIndex;
      _tabTransitionMovesForward = index > currentIndex;
      currentIndex = index;
      if (syncSingleton) {
        singleton.setPage(index);
      }
      button = false;
      if (currentIndex == 3 || currentIndex == 4) {
        checkTab();
        _fabAnimationController.forward(from: 0);
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _popToNavbarRoot() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
  }

  List<TutorialStep> _buildTutorialSteps() {
    return <TutorialStep>[
      TutorialStep(
        targetKey: _navItemKeys[0],
        title: 'Home Dashboard',
        description:
            'Home shows your symptom and medication trend graphs at a glance.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(0);
        },
      ),
      TutorialStep(
        targetKey: _navItemKeys[1],
        title: 'Manage',
        description:
            'Manage is where you create symptom and medication entries.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(1);
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.logSymptomQuickActionKey,
        title: 'Start Symptom Entry',
        description:
            'Tap Log Symptom to open the symptom form and capture what you felt.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(1);
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.symptomInputKey,
        title: 'Describe the Symptom',
        description:
            'Enter the symptom details here, then choose severity and time.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushNamed('/editLogScreen');
          });
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.saveSymptomButtonKey,
        title: 'Save Symptom',
        description:
            'When details are ready, save the entry to track symptom trends.',
      ),
      TutorialStep(
        targetKey: TutorialTargets.addMedicationQuickActionKey,
        title: 'Start Medication Entry',
        description:
            'Next, open Add Medication to create a medication schedule.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(1);
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.medicationNameInputKey,
        title: 'Medication Details',
        description:
            'Enter medication name, then choose templates or select specific days.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushNamed('/editScheduleScreen');
          });
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.saveMedicationButtonKey,
        title: 'Save Medication',
        description:
            'Save to add this medication schedule to your weekly plan.',
      ),
      TutorialStep(
        targetKey: TutorialTargets.medicationsToolCardKey,
        title: 'Open Medication List',
        description:
            'Open Medications to review saved schedules and details in one place.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(1);
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.scheduleAddMedicationKey,
        title: 'Add from Medication View',
        description:
            'Use this button in Medications to quickly add another schedule.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).push(
              buildSubtleFadeRoute(page: const ScheduleScreen()),
            );
          });
        },
      ),
      TutorialStep(
        targetKey: _navItemKeys[2],
        title: 'Recovery',
        description:
            'Recovery has guided speech and exercise videos. Tap the tab to open it.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(2);
        },
      ),
      TutorialStep(
        targetKey: _exerciseCardKey,
        title: 'Open Physical Exercises',
        description:
            'Open Physical Exercises to view official guided recovery lessons.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(2);
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.firstExerciseCardKey,
        title: 'Choose an Exercise Video',
        description:
            'Pick a lesson card to open its guided exercise video player.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).push(
              buildSubtleFadeRoute(page: const ExerciseScreen()),
            );
          });
        },
      ),
      TutorialStep(
        targetKey: TutorialTargets.exerciseVideoPlayerKey,
        title: 'Practice in Video Mode',
        description:
            'Use this player to follow the movement routine step by step.',
        onStepStarted: () {
          _popToNavbarRoot();
          final firstExerciseId = singleton.exercises.keys.isNotEmpty
              ? singleton.exercises.keys.first
              : '';
          if (firstExerciseId.isEmpty) return;
          singleton.setCurrentUrl(firstExerciseId);
          _switchTabForTutorial(2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushNamed('/exerciseVideoScreen');
          });
        },
      ),
      TutorialStep(
        targetKey: _navItemKeys[3],
        title: 'Community',
        description:
            'Share and read posts in the community feed. Tap Feed or Resources in the tabs.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(3);
        },
      ),
      TutorialStep(
        targetKey: _navItemKeys[4],
        title: 'Profile',
        description:
            'Your profile and progress summary. Tap the tab to open it.',
        onStepStarted: () {
          _popToNavbarRoot();
          _switchTabForTutorial(4);
        },
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
      color: colors.surface.blend(colors.primary, 0.14),
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
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
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
            Expanded(
              child: _buildAnimatedTabBody(),
            ),
          ],
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
            ClipRect(
              child: Container(
                key: _titleKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  layoutBuilder: (currentChild, _) {
                    return currentChild ?? const SizedBox.shrink();
                  },
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    navItems[currentIndex].label,
                    key: ValueKey<int>(currentIndex),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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

  Widget _buildAnimatedTabBody() {
    final colors = context.colors;
    final visibleIndices = <int>[
      if (_previousIndex != currentIndex) _previousIndex,
      currentIndex,
    ];

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: visibleIndices.map((index) {
          final isCurrent = index == currentIndex;

          Offset targetOffset;
          if (isCurrent) {
            targetOffset = Offset.zero;
          } else {
            targetOffset = _tabTransitionMovesForward
                ? const Offset(-0.025, 0)
                : const Offset(0.025, 0);
          }

          return TickerMode(
            key: ValueKey<int>(index),
            enabled: true,
            child: IgnorePointer(
              ignoring: !isCurrent,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: targetOffset,
                child: RepaintBoundary(
                  child: ColoredBox(
                    color: colors.background,
                    child: _tabs[index],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: itemKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? colors.primary : colors.navUnselected,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style:
                  (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
                      .copyWith(
                color: isSelected ? colors.primary : colors.navUnselected,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 9,
              ),
              child: Text(item.label),
            ),
          ],
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
