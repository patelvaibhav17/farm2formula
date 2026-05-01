import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/harvesting/screens/harvesting_dashboard.dart';
import '../../features/harvesting/screens/register_batch_screen.dart';
import '../../features/logistics/screens/logistics_dashboard.dart';
import '../../features/logistics/screens/scan_batch_screen.dart';
import '../../features/laboratory/screens/laboratory_dashboard.dart';
import '../../features/laboratory/screens/submit_qa_screen.dart';
import '../../features/manufacturing/screens/manufacturing_dashboard.dart';
import '../../features/manufacturing/screens/create_lot_screen.dart';
import '../../features/consumer/screens/consumer_scanner_screen.dart';
import '../../features/consumer/screens/consumer_timeline_screen.dart';
import '../../features/auth/screens/user_profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/role_selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      path: '/harvesting',
      builder: (context, state) => const HarvestingDashboard(),
      routes: [
        GoRoute(
          path: 'register',
          builder: (context, state) => const RegisterBatchScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/logistics',
      builder: (context, state) => const LogisticsDashboard(),
      routes: [
        GoRoute(
          path: 'scan',
          builder: (context, state) => const ScanBatchScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/laboratory',
      builder: (context, state) => const LaboratoryDashboard(),
       routes: [
        GoRoute(
          path: 'submit/:batchId',
          builder: (context, state) => SubmitQAScreen(batchId: state.pathParameters['batchId']!),
        ),
      ],
    ),
    GoRoute(
      path: '/manufacturing',
      builder: (context, state) => const ManufacturingDashboard(),
      routes: [
        GoRoute(
          path: 'create-lot',
          builder: (context, state) => const CreateLotScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/consumer',
      builder: (context, state) => const ConsumerScannerScreen(),
      routes: [
        GoRoute(
          path: 'timeline/:lotId',
          builder: (context, state) => ConsumerTimelineScreen(lotId: state.pathParameters['lotId']!),
        ),
      ],
    ),
  ],
);
