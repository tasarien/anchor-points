import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/notifications_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/other_AP_screens.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/settings_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator%20copy.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  PersistentTabController _controller = PersistentTabController();
  List<Widget> _screens = [
    AnchorPointScreen(),
    OtherAPScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    DataProvider appData = context.watch<DataProvider>();
    return Scaffold(
      body: appData.isReloading
          ? Center(child: LoadingIndicator())
          : PersistentTabView(
              context,
              controller: _controller,
              screens: _screens,
              items: [
                PersistentBottomNavBarItem(
                  icon: FaIcon(
                    AnchorPointIcons.anchor_point_icon,
                    color: colorScheme.onSurface,
                  ),
                  inactiveIcon: FaIcon(
                    AnchorPointIcons.anchor_point_icon,
                    color: colorScheme.tertiary,
                  ),
                  title: "Anchor Point",
                  activeColorPrimary: colorScheme.error,
                ),
                PersistentBottomNavBarItem(
                  icon: FaIcon(
                    FontAwesomeIcons.circleNodes,
                    color: colorScheme.onSurface,
                  ),
                  inactiveIcon: FaIcon(
                    FontAwesomeIcons.circleNodes,
                    color: colorScheme.tertiary,
                  ),
                  title: "Other Anchor Points",
                  activeColorPrimary: colorScheme.error,
                ),
                PersistentBottomNavBarItem(
                  icon: FaIcon(
                    FontAwesomeIcons.bell,
                    color: colorScheme.onSurface,
                  ),
                  inactiveIcon: FaIcon(
                    FontAwesomeIcons.bell,
                    color: colorScheme.tertiary,
                  ),
                  title: "Notifications",
                  activeColorPrimary: colorScheme.error,
                ),
                PersistentBottomNavBarItem(
                  icon: FaIcon(
                    FontAwesomeIcons.gears,
                    color: colorScheme.onSurface,
                  ),
                  inactiveIcon: FaIcon(
                    FontAwesomeIcons.gear,
                    color: colorScheme.tertiary,
                  ),
                  title: "Settings",
                  activeColorPrimary: colorScheme.error,
                ),
              ],
              handleAndroidBackButtonPress: true, // Default is true.
              resizeToAvoidBottomInset:
                  true, // This needs to be true if you want to move up the screen on a non-scrollable screen when keyboard appears. Default is true.
              stateManagement: true, // Default is true.
              hideNavigationBarWhenKeyboardAppears: true,
              popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
              padding: const EdgeInsets.only(top: 8),
              backgroundColor: colorScheme.surface,

              isVisible: true,
              animationSettings: const NavBarAnimationSettings(
                navBarItemAnimation: ItemAnimationSettings(
                  // Navigation Bar's items animation properties.
                  duration: Duration(milliseconds: 400),
                  curve: Curves.ease,
                ),
                screenTransitionAnimation: ScreenTransitionAnimationSettings(
                  animateTabTransition: true,
                  duration: Duration(milliseconds: 200),
                  screenTransitionAnimationType:
                      ScreenTransitionAnimationType.slide,
                ),
              ),
              confineToSafeArea: true,
              navBarHeight: kBottomNavigationBarHeight,
              navBarStyle: NavBarStyle.style12,
            ),
    );
  }
}
