import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_models.dart';
import '../../features/auth/forgot_otp_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/forgot_reset_screen.dart';
import '../../features/auth/forgot_success_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/bills/bill_history_screen.dart';
import '../../features/billing/create_bill_screen.dart';
import '../../features/billing/invoice_preview_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/medical_store/add_medical_store_screen.dart';
import '../../features/medical_store/medical_store_screen.dart';
import '../../features/products/add_product_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../widgets/app_shell.dart';
import '../constants/app_routes.dart';
import '../providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final path = state.uri.path;

      // Check if user is navigating to an auth route
      final isAuthRoute = path == AppRoutes.login ||
          path == AppRoutes.signup ||
          path == AppRoutes.splash ||
          path == AppRoutes.otp ||
          path == AppRoutes.forgot ||
          path == AppRoutes.forgotOtp ||
          path == AppRoutes.forgotReset ||
          path == AppRoutes.forgotSuccess;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && (path == AppRoutes.login || path == AppRoutes.signup || path == AppRoutes.splash)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _page(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _page(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => _page(state, const SignupScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) => _page(state, const OtpScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        pageBuilder: (context, state) =>
            _page(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotOtp,
        pageBuilder: (context, state) => _page(state, const ForgotOtpScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotReset,
        pageBuilder: (context, state) =>
            _page(state, const ForgotResetScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotSuccess,
        pageBuilder: (context, state) =>
            _page(state, const ForgotSuccessScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) =>
                    _page(state, const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bills,
                pageBuilder: (context, state) =>
                    _page(state, const BillHistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                pageBuilder: (context, state) =>
                    _page(state, const ProductsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.categories,
                pageBuilder: (context, state) =>
                    _page(state, const CategoriesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stores,
                pageBuilder: (context, state) =>
                    _page(state, const MedicalStoreScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _page(state, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _page(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.createBill,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(state, const CreateBillScreen()),
      ),
      GoRoute(
        path: AppRoutes.invoicePreview,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final bill = state.extra as BillRecord?;
          return _page(state, InvoicePreviewScreen(bill: bill));
        },
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(state, const AddProductScreen()),
      ),
      GoRoute(
        path: AppRoutes.addStore,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(state, const AddMedicalStoreScreen()),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(state, const EditProfileScreen()),
      ),
    ],
  );
});

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
