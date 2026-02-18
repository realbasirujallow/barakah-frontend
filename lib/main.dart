import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:barakah_app/screens/login_screen.dart';
import 'package:barakah_app/screens/signup_screen.dart';
import 'package:barakah_app/screens/dashboard_screen.dart';
import 'package:barakah_app/screens/assets_screen.dart';
import 'package:barakah_app/screens/zakat_screen.dart';
import 'package:barakah_app/screens/prices_screen.dart';
import 'package:barakah_app/screens/transactions_screen.dart';
import 'package:barakah_app/screens/prayer_times_screen.dart';
import 'package:barakah_app/screens/reports_screen.dart';
import 'package:barakah_app/screens/settings_screen.dart';
import 'package:barakah_app/screens/onboarding_screen.dart';
import 'package:barakah_app/screens/halal_screener_screen.dart';
import 'package:barakah_app/screens/analytics_screen.dart';
import 'package:barakah_app/screens/forgot_password_screen.dart';
import 'package:barakah_app/screens/profile_screen.dart';
import 'package:barakah_app/screens/savings_goals_screen.dart';
import 'package:barakah_app/screens/budget_screen.dart';
import 'package:barakah_app/screens/debt_tracker_screen.dart';
import 'package:barakah_app/screens/bills_screen.dart';
import 'package:barakah_app/screens/hawl_tracker_screen.dart';
import 'package:barakah_app/screens/sadaqah_screen.dart';
import 'package:barakah_app/screens/wasiyyah_screen.dart';
import 'package:barakah_app/screens/waqf_screen.dart';
import 'package:barakah_app/screens/riba_detector_screen.dart';
import 'package:barakah_app/screens/auto_categorize_screen.dart';
import 'package:barakah_app/screens/net_worth_screen.dart';
import 'package:barakah_app/screens/shared_finances_screen.dart';
import 'package:barakah_app/screens/investments_screen.dart';
import 'package:barakah_app/screens/credit_score_screen.dart';
import 'package:barakah_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  final showOnboarding = await OnboardingScreen.shouldShow();
  // Initialize notifications
  await NotificationService().init();
  runApp(BarakahApp(authService: authService, showOnboarding: showOnboarding));
}

class BarakahApp extends StatelessWidget {
  final AuthService authService;
  final bool showOnboarding;

  const BarakahApp({super.key, required this.authService, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthService, ThemeProvider>(
        builder: (context, auth, themeProvider, _) {
          return MaterialApp(
            title: 'Barakah',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: showOnboarding
                ? '/onboarding'
                : (auth.isLoggedIn ? '/dashboard' : '/login'),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/assets': (context) => const AssetsScreen(),
              '/zakat': (context) => const ZakatScreen(),
              '/prices': (context) => const PricesScreen(),
              '/transactions': (context) => const TransactionsScreen(),
              '/prayers': (context) => const PrayerTimesScreen(),
              '/reports': (context) => const ReportsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/halal': (context) => const HalalScreenerScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/savings': (context) => const SavingsGoalsScreen(),
              '/budget': (context) => const BudgetScreen(),
              '/debts': (context) => const DebtTrackerScreen(),
              '/bills': (context) => const BillsScreen(),
              '/hawl': (context) => const HawlTrackerScreen(),
              '/sadaqah': (context) => const SadaqahScreen(),
              '/wasiyyah': (context) => const WasiyyahScreen(),
              '/waqf': (context) => const WaqfScreen(),
              '/riba': (context) => const RibaDetectorScreen(),
              '/auto-categorize': (context) => const AutoCategorizeScreen(),
              '/net-worth': (context) => const NetWorthScreen(),
              '/shared-finances': (context) => const SharedFinancesScreen(),
              '/investments': (context) => const InvestmentsScreen(),
              '/credit-score': (context) => const CreditScoreScreen(),
            },
          );
        },
      ),
    );
  }
}
