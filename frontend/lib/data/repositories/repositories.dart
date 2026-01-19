import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/api_client.dart';
import '../models/job_requisition.dart';
import '../models/candidate.dart';
import '../models/interview.dart';
import '../models/offer.dart';
import '../models/job_posting.dart';
import '../models/application.dart';
import '../models/onboarding_task.dart';
import '../models/referral.dart';
import '../models/dashboard_metrics.dart';
import '../../core/services/token_storage.dart';

class JobRequisitionRepository {
  final ApiClient _apiClient;

  JobRequisitionRepository(this._apiClient);

  Future<List<JobRequisition>> getRequisitions({
    int skip = 0,
    int limit = 100,
    String? status,
    String? search,
  }) => _apiClient.getRequisitions(skip: skip, limit: limit, status: status, search: search);

  Future<JobRequisition> createRequisition(Map<String, dynamic> data) =>
      _apiClient.createRequisition(data);

  Future<JobRequisition> getRequisition(String id) => _apiClient.getRequisition(id);

  Future<JobRequisition> updateRequisition(String id, Map<String, dynamic> data) =>
      _apiClient.updateRequisition(id, data);

  Future<JobRequisition> approveRequisition(String id, Map<String, dynamic> data) =>
      _apiClient.approveRequisition(id, data);
}

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    final response = await _apiClient.login(credentials);
    final data = response.data as Map<String, dynamic>;
    
    // Save tokens to secure storage
    await TokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    
    return data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _apiClient.register(userData);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiClient.getCurrentUser();
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _apiClient.logout();
    // Clear tokens from secure storage
    await TokenStorage.clearTokens();
  }
}

class CandidateRepository {
  final ApiClient _apiClient;

  CandidateRepository(this._apiClient);

  Future<List<Candidate>> getCandidates({
    int skip = 0,
    int limit = 100,
    String? search,
  }) => _apiClient.getCandidates(skip: skip, limit: limit, search: search);

  Future<Candidate> createCandidate(Map<String, dynamic> data) =>
      _apiClient.createCandidate(data);

  Future<Candidate> getCandidate(String id) => _apiClient.getCandidate(id);

  Future<void> uploadResume(String candidateId, dynamic file) async {
    await _apiClient.uploadResume(candidateId, file);
  }

  Future<void> parseResume(String candidateId) async {
    await _apiClient.parseResume(candidateId);
  }
}

class InterviewRepository {
  final ApiClient _apiClient;

  InterviewRepository(this._apiClient);

  Future<List<Interview>> getInterviews({
    int skip = 0,
    int limit = 100,
    String? status,
  }) => _apiClient.getInterviews(skip: skip, limit: limit, status: status);

  Future<Interview> scheduleInterview(Map<String, dynamic> data) =>
      _apiClient.scheduleInterview(data);
}

class OfferRepository {
  final ApiClient _apiClient;

  OfferRepository(this._apiClient);

  Future<List<Offer>> getOffers({
    int skip = 0,
    int limit = 100,
    String? status,
  }) => _apiClient.getOffers(skip: skip, limit: limit, status: status);

  Future<Offer> createOffer(Map<String, dynamic> data) =>
      _apiClient.createOffer(data);
}

class JobPostingRepository {
  final ApiClient _apiClient;

  JobPostingRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getJobPostings({
    int skip = 0,
    int limit = 100,
    String? status,
    String? search,
  }) async {
    final response = await _apiClient.getJobPostings(skip: skip, limit: limit, status: status, search: search);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> getJobPosting(String id) async {
    final response = await _apiClient.getJobPosting(id);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createJobPosting(Map<String, dynamic> data) async {
    final response = await _apiClient.createJobPosting(data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateJobPosting(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.updateJobPosting(id, data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteJobPosting(String id) => _apiClient.deleteJobPosting(id);

  Future<Map<String, dynamic>> publishJobPosting(String id, Map<String, dynamic> platforms) async {
    final response = await _apiClient.publishJobPosting(id, platforms);
    return response.data as Map<String, dynamic>;
  }
}

class ApplicationRepository {
  final ApiClient _apiClient;

  ApplicationRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getApplications({
    int skip = 0,
    int limit = 100,
    String? status,
    String? jobPostingId,
  }) async {
    final response = await _apiClient.getApplications(skip: skip, limit: limit, status: status, jobPostingId: jobPostingId);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> getApplication(String id) async {
    final response = await _apiClient.getApplication(id);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> data) async {
    final response = await _apiClient.submitApplication(data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateApplicationStatus(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.updateApplicationStatus(id, data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> shortlistApplication(String id) async {
    final response = await _apiClient.shortlistApplication(id);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectApplication(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.rejectApplication(id, data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rankAll() async {
    final response = await _apiClient.rankAll();
    return response.data as Map<String, dynamic>;
  }
}

class OnboardingRepository {
  final ApiClient _apiClient;

  OnboardingRepository(this._apiClient);

  Future<Map<String, dynamic>> getOnboardingStatus(String offerId) async {
    final response = await _apiClient.getOnboardingStatus(offerId);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createOnboardingTask(Map<String, dynamic> data) async {
    final response = await _apiClient.createOnboardingTask(data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyDocument(Map<String, dynamic> data) async {
    final response = await _apiClient.verifyDocument(data);
    return response.data as Map<String, dynamic>;
  }
}

class ReferralRepository {
  final ApiClient _apiClient;

  ReferralRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getReferrals({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    final response = await _apiClient.getReferrals(skip: skip, limit: limit, status: status);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> getReferralStatus(String id) async {
    final response = await _apiClient.getReferralStatus(id);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createReferral(Map<String, dynamic> data) async {
    final response = await _apiClient.createReferral(data);
    return response.data as Map<String, dynamic>;
  }
}

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<Map<String, dynamic>> getPipelineStats() async {
    final response = await _apiClient.getPipelineStats();
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await _apiClient.getDashboardMetrics();
    return response.data as Map<String, dynamic>;
  }
}

class CandidatePortalRepository {
  final ApiClient _apiClient;

  CandidatePortalRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final response = await _apiClient.getMyApplications();
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getMyInterviews() async {
    final response = await _apiClient.getMyInterviews();
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getMyOffers() async {
    final response = await _apiClient.getMyOffers();
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<List<Map<String, dynamic>>> getPortalMessages() async {
    final response = await _apiClient.getPortalMessages();
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  Future<Map<String, dynamic>> sendPortalMessage(Map<String, dynamic> data) async {
    final response = await _apiClient.sendPortalMessage(data);
    return response.data as Map<String, dynamic>;
  }
}
