import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/api_client.dart';
import '../../data/repositories/repositories.dart';
import '../../data/models/job_requisition.dart';
import '../../data/models/candidate.dart';
import '../../data/models/interview.dart';
import '../../data/models/offer.dart';
import '../../data/models/application.dart';
import '../../data/models/dashboard_metrics.dart';

// API Client Provider
final dioProvider = Provider((ref) => createDio());
final apiClientProvider = Provider((ref) => ApiClient(ref.watch(dioProvider)));

// Repository Providers
final jobRequisitionRepositoryProvider = Provider(
  (ref) => JobRequisitionRepository(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final candidateRepositoryProvider = Provider(
  (ref) => CandidateRepository(ref.watch(apiClientProvider)),
);

final interviewRepositoryProvider = Provider(
  (ref) => InterviewRepository(ref.watch(apiClientProvider)),
);

final offerRepositoryProvider = Provider(
  (ref) => OfferRepository(ref.watch(apiClientProvider)),
);

final jobPostingRepositoryProvider = Provider(
  (ref) => JobPostingRepository(ref.watch(apiClientProvider)),
);

final applicationRepositoryProvider = Provider(
  (ref) => ApplicationRepository(ref.watch(apiClientProvider)),
);

final onboardingRepositoryProvider = Provider(
  (ref) => OnboardingRepository(ref.watch(apiClientProvider)),
);

final referralRepositoryProvider = Provider(
  (ref) => ReferralRepository(ref.watch(apiClientProvider)),
);

final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

final candidatePortalRepositoryProvider = Provider(
  (ref) => CandidatePortalRepository(ref.watch(apiClientProvider)),
);

// Job Requisitions Providers
final jobRequisitionsProvider =
    FutureProvider.family<List<JobRequisition>, JobRequisitionFilter>(
        (ref, filter) async {
  final repository = ref.watch(jobRequisitionRepositoryProvider);
  return repository.getRequisitions(
      status: filter.status, search: filter.search);
});

final jobRequisitionDetailProvider =
    FutureProvider.family<JobRequisition, String>((ref, id) async {
  final repository = ref.watch(jobRequisitionRepositoryProvider);
  return repository.getRequisition(id);
});

// Candidates Providers
final candidatesProvider =
    FutureProvider.family<List<Candidate>, String?>((ref, search) async {
  final repository = ref.watch(candidateRepositoryProvider);
  return repository.getCandidates(search: search);
});

final candidateDetailProvider =
    FutureProvider.family<Candidate, String>((ref, id) async {
  final repository = ref.watch(candidateRepositoryProvider);
  return repository.getCandidate(id);
});

// Interviews Providers
final interviewsProvider =
    FutureProvider.family<List<Interview>, String?>((ref, status) async {
  final repository = ref.watch(interviewRepositoryProvider);
  return repository.getInterviews(status: status);
});

// Offers Providers
final offersProvider =
    FutureProvider.family<List<Offer>, String?>((ref, status) async {
  final repository = ref.watch(offerRepositoryProvider);
  return repository.getOffers(status: status);
});

// Job Postings Providers
final jobPostingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, status) async {
  final repository = ref.watch(jobPostingRepositoryProvider);
  return repository.getJobPostings(status: status);
});

final jobPostingDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repository = ref.watch(jobPostingRepositoryProvider);
  return repository.getJobPosting(id);
});

// Applications Providers
final applicationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ApplicationFilter?>(
        (ref, filter) async {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.getApplications(
    status: filter?.status,
    jobPostingId: filter?.jobPostingId,
  );
});

final applicationDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.getApplication(id);
});

// Onboarding Providers
final onboardingStatusProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, offerId) async {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getOnboardingStatus(offerId);
});

// Referrals Providers
final referralsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, status) async {
  final repository = ref.watch(referralRepositoryProvider);
  return repository.getReferrals(status: status);
});

final referralDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repository = ref.watch(referralRepositoryProvider);
  return repository.getReferralStatus(id);
});

// Dashboard Providers
final pipelineStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getPipelineStats();
});

final dashboardMetricsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardMetrics();
});

// Candidate Portal Providers
final myApplicationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(candidatePortalRepositoryProvider);
  return repository.getMyApplications();
});

final myInterviewsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(candidatePortalRepositoryProvider);
  return repository.getMyInterviews();
});

final myOffersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(candidatePortalRepositoryProvider);
  return repository.getMyOffers();
});

// Auth Providers
final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
});
