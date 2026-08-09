import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../screens/browse/browse_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/saved/saved_screen.dart';
import '../../screens/upload/upload_screen.dart';
import 'bottom_nav_bar.dart';

enum AppTab { home, browse, upload, saved, profile }

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.index;
  }

  void _setTab(AppTab tab) {
    if (_currentIndex == tab.index) {
      return;
    }
    setState(() => _currentIndex = tab.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onBrowseTap: () => _setTab(AppTab.browse),
            onUploadTap: () => _setTab(AppTab.upload),
            onSavedTap: () => _setTab(AppTab.saved),
            onProfileTap: () => _setTab(AppTab.profile),
            onSearchTap: () => context.push(AppRoutes.search),
            onSignInTap: () => context.push(AppRoutes.login),
            onSignUpTap: () => context.push(AppRoutes.signup),
          ),
          const BrowseScreen(),
          UploadScreen(
            onBrowseTap: () => _setTab(AppTab.browse),
            onSavedTap: () => _setTab(AppTab.saved),
            onProfileTap: () => _setTab(AppTab.profile),
            onSignInTap: () => context.push(AppRoutes.login),
            onSignUpTap: () => context.push(AppRoutes.signup),
          ),
          SavedScreen(
            onBrowseTap: () => _setTab(AppTab.browse),
            onSignInTap: () => context.push(AppRoutes.login),
          ),
          ProfileScreen(
            onSavedTap: () => _setTab(AppTab.saved),
            onSignInTap: () => context.push(AppRoutes.login),
            onSignUpTap: () => context.push(AppRoutes.signup),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

