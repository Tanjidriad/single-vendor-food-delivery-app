import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import 'app_bottom_nav_bar.dart';

/// Customer shell tabs. Replace builders with `SvgPicture.asset(...)` when SVGs are ready.
const customerBottomNavDestinations = <AppBottomNavDestination>[
  AppBottomNavDestination(
    label: 'Home',
    icon: _homeIcon,
    activeIcon: _homeActiveIcon,
  ),
  AppBottomNavDestination(
    label: 'Menu',
    icon: _menuIcon,
    activeIcon: _menuActiveIcon,
  ),
  AppBottomNavDestination(
    label: 'Offers',
    icon: _offersIcon,
    activeIcon: _offersActiveIcon,
  ),
  AppBottomNavDestination(
    label: 'Profile',
    icon: _profileIcon,
    activeIcon: _profileActiveIcon,
  ),
];

Widget _homeIcon(Color color) => Icon(AppIcons.home, size: 22, color: color);

Widget _homeActiveIcon(Color color) => Icon(AppIcons.homeFilled, size: 22, color: color);

Widget _menuIcon(Color color) => Icon(Icons.grid_view_outlined, size: 22, color: color);

Widget _menuActiveIcon(Color color) => Icon(Icons.grid_view_rounded, size: 22, color: color);

Widget _offersIcon(Color color) => Icon(AppIcons.offers, size: 22, color: color);

Widget _offersActiveIcon(Color color) => Icon(AppIcons.offersFilled, size: 22, color: color);

Widget _profileIcon(Color color) => Icon(AppIcons.profile, size: 22, color: color);

Widget _profileActiveIcon(Color color) => Icon(AppIcons.profileFilled, size: 22, color: color);
