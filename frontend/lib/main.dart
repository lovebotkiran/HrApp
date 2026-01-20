import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/presentation/screens/auth/login_screen.dart';
import 'package:agentichr_frontend/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:agentichr_frontend/presentation/screens/job_requisitions/job_requisitions_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/candidates/candidates_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/interviews/interviews_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/offers/offers_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/job_postings/job_postings_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/applications/applications_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/onboarding/onboarding_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/referrals/referrals_list_screen.dart';
import 'package:agentichr_frontend/presentation/screens/candidate_portal/candidate_portal_screen.dart';
import 'package:agentichr_frontend/presentation/screens/analytics/analytics_screen.dart';
import 'package:agentichr_frontend/presentation/screens/settings/settings_screen.dart';
import 'package:agentichr_frontend/presentation/screens/job_requisitions/create_job_requisition_screen.dart';
import 'package:agentichr_frontend/presentation/screens/candidates/create_candidate_screen.dart';
import 'package:agentichr_frontend/presentation/screens/interviews/create_interview_screen.dart';
import 'package:agentichr_frontend/presentation/screens/offers/create_offer_screen.dart';
import 'package:agentichr_frontend/presentation/screens/candidates/candidate_detail_screen.dart';
import 'package:agentichr_frontend/presentation/screens/applications/ai_rankings_screen.dart';
import 'package:agentichr_frontend/data/models/candidate.dart';

import 'package:agentichr_frontend/presentation/screens/job_postings/create_job_posting_screen.dart';
import 'package:agentichr_frontend/presentation/screens/job_postings/application_form_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    const ProviderScope(
      child: AgenticHRApp(),
    ),
  );
}

class AgenticHRApp extends StatelessWidget {
  const AgenticHRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgenticHR',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Responsive Framework
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),

      // Routes
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/job-requisitions': (context) => const JobRequisitionsListScreen(),
        '/job-postings': (context) => const JobPostingsListScreen(),
        '/candidates': (context) => const CandidatesListScreen(),
        '/applications': (context) => const ApplicationsListScreen(),
        '/interviews': (context) => const InterviewsListScreen(),
        '/offers': (context) => const OffersListScreen(),
        '/onboarding': (context) => const OnboardingListScreen(),
        '/referrals': (context) => const ReferralsListScreen(),
        '/candidate-portal': (context) => const CandidatePortalScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/job-requisitions/create': (context) =>
            const CreateJobRequisitionScreen(),
        '/job-postings/create': (context) => const CreateJobPostingScreen(),
        '/candidates/create': (context) => const CreateCandidateScreen(),
        '/interviews/create': (context) => const CreateInterviewScreen(),
        '/offers/create': (context) => const CreateOfferScreen(),
        '/ai-rankings': (context) => const AIRankingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/candidates/detail') {
          final id = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => CandidateDetailScreen(candidateId: id),
          );
        }
        if (settings.name == '/candidates/edit') {
          final candidate = settings.arguments as Candidate;
          return MaterialPageRoute(
            builder: (context) => CreateCandidateScreen(candidate: candidate),
          );
        }
        if (settings.name == '/apply') {
          final id = settings.arguments as String?;
          if (id != null) {
            return MaterialPageRoute(
              builder: (context) => ApplicationFormScreen(jobPostingId: id),
            );
          }
        }
        if (settings.name != null && settings.name!.startsWith('/apply/')) {
          final id = settings.name!.replaceFirst('/apply/', '');
          return MaterialPageRoute(
            builder: (context) => ApplicationFormScreen(jobPostingId: id),
          );
        }

        return null;
      },
    );
  }
}
