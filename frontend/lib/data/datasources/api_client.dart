import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/job_requisition.dart';
import '../models/candidate.dart';
import '../models/interview.dart';
import '../models/offer.dart';
import '../models/department_skill.dart';
import '../../core/services/token_storage.dart';
import '../../main.dart';

part 'api_client.g.dart';

// Create Dio instance with base configuration
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add auth interceptor to include token in requests
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from secure storage
        final token = await TokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors (token expired)
        if (error.response?.statusCode == 401) {
          final refreshToken = await TokenStorage.getRefreshToken();

          if (refreshToken != null) {
            try {
              // Create a temporary Dio instance for the refresh request
              // to avoid infinite loops and interceptor conflicts
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: 'http://127.0.0.1:8000/api/v1',
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              // Call refresh endpoint
              final response = await refreshDio.post('/auth/refresh',
                  queryParameters: {'refresh_token': refreshToken});

              if (response.statusCode == 200) {
                // Parse new tokens
                final data = response.data;
                final newAccessToken = data['access_token'];
                final newRefreshToken = data['refresh_token'];

                // Save new tokens
                await TokenStorage.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                );

                // Retry the original request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final cloneReq = await dio.fetch(options);
                return handler.resolve(cloneReq);
              }
            } catch (e) {
              // Refresh failed - clean up
              await TokenStorage.clearTokens();
              navigatorKey.currentState
                  ?.pushNamedAndRemoveUntil('/login', (route) => false);
            }
          } else {
            // No refresh token - clean up
            await TokenStorage.clearTokens();
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
        return handler.next(error);
      },
    ),
  );

  // Add interceptors for logging and error handling
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
}

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // ============================================================================
  // Authentication Endpoints
  // ============================================================================

  @POST('/auth/login')
  Future<HttpResponse<dynamic>> login(@Body() Map<String, dynamic> credentials);

  @POST('/auth/register')
  Future<HttpResponse<dynamic>> register(@Body() Map<String, dynamic> userData);

  @GET('/auth/me')
  Future<HttpResponse<dynamic>> getCurrentUser();

  @POST('/auth/logout')
  Future<void> logout();

  // ============================================================================
  // Job Requisitions Endpoints
  // ============================================================================

  @GET('/job-requisitions/')
  Future<List<JobRequisition>> getRequisitions({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 100,
    @Query('status') String? status,
    @Query('department') String? department,
    @Query('search') String? search,
  });

  @GET('/job-requisitions/departments')
  Future<List<String>> getDepartments();

  @GET('/job-requisitions/{id}')
  Future<JobRequisition> getRequisition(@Path('id') String id);

  @POST('/job-requisitions/')
  Future<JobRequisition> createRequisition(@Body() Map<String, dynamic> data);

  @PUT('/job-requisitions/{id}')
  Future<JobRequisition> updateRequisition(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/job-requisitions/{id}')
  Future<void> deleteRequisition(@Path('id') String id);

  @POST('/job-requisitions/{id}/approve')
  Future<JobRequisition> approveRequisition(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/job-requisitions/{id}/generate-jd')
  Future<JobRequisition> generateJobDescription(@Path('id') String id);

  @POST('/job-requisitions/{id}/share-linkedin')
  Future<HttpResponse<dynamic>> shareToLinkedIn(@Path('id') String id);

  @GET('/job-requisitions/skills/{department}')
  Future<List<DepartmentSkill>> getDepartmentSkills(
    @Path('department') String department,
  );

  @POST('/job-requisitions/skills')
  Future<DepartmentSkill> addDepartmentSkill(
    @Body() Map<String, dynamic> data,
  );

  // ============================================================================
  // Job Postings Endpoints - Using HttpResponse for dynamic data
  // ============================================================================

  @GET('/job-postings/')
  Future<HttpResponse<dynamic>> getJobPostings({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 100,
    @Query('status') String? status,
    @Query('search') String? search,
    @Query('department') String? department,
  });

  @GET('/job-postings/{id}')
  Future<HttpResponse<dynamic>> getJobPosting(@Path('id') String id);

  @POST('/job-postings/')
  Future<HttpResponse<dynamic>> createJobPosting(
      @Body() Map<String, dynamic> data);

  @PUT('/job-postings/{id}')
  Future<HttpResponse<dynamic>> updateJobPosting(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/job-postings/{id}')
  Future<void> deleteJobPosting(@Path('id') String id);

  @POST('/job-postings/{id}/publish')
  Future<HttpResponse<dynamic>> publishJobPosting(
    @Path('id') String id,
    @Body() Map<String, dynamic> platforms,
  );

  @POST('/job-postings/{id}/expire')
  Future<HttpResponse<dynamic>> expireJobPosting(@Path('id') String id);

  @PUT('/job-postings/{id}/status')
  Future<HttpResponse<dynamic>> updateJobPostingStatus(
    @Path('id') String id,
    @Body() Map<String, dynamic> status,
  );

  @POST('/job-postings/{id}/share-linkedin')
  Future<HttpResponse<dynamic>> shareJobPostingToLinkedIn(
      @Path('id') String id);

  // ============================================================================
  // Candidates Endpoints
  // ============================================================================

  @GET('/candidates/')
  Future<List<Candidate>> getCandidates({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 100,
    @Query('search') String? search,
    @Query('skills') String? skills,
  });

  @GET('/candidates/{id}')
  Future<Candidate> getCandidate(@Path('id') String id);

  @POST('/candidates/')
  Future<Candidate> createCandidate(@Body() Map<String, dynamic> data);

  @PUT('/candidates/{id}')
  Future<Candidate> updateCandidate(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/candidates/{id}')
  Future<void> deleteCandidate(@Path('id') String id);

  @POST('/candidates/{id}/upload-resume')
  Future<HttpResponse<dynamic>> uploadResume(
    @Path('id') String id,
    @Body() FormData file,
  );

  @POST('/candidates/{id}/parse-resume')
  Future<HttpResponse<dynamic>> parseResume(@Path('id') String id);

  @POST('/candidates/{id}/blacklist')
  Future<Candidate> blacklistCandidate(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  // ============================================================================
  // Applications Endpoints - Using HttpResponse for dynamic data
  // ============================================================================

  @GET('/applications/')
  Future<HttpResponse<dynamic>> getApplications({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 100,
    @Query('status') String? status,
    @Query('job_posting_id') String? jobPostingId,
    @Query('department') String? department,
  });

  @GET('/applications/{id}')
  Future<HttpResponse<dynamic>> getApplication(@Path('id') String id);

  @POST('/applications/')
  Future<HttpResponse<dynamic>> submitApplication(
      @Body() Map<String, dynamic> data);

  @PUT('/applications/{id}/status')
  Future<HttpResponse<dynamic>> updateApplicationStatus(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/applications/{id}/shortlist')
  Future<HttpResponse<dynamic>> shortlistApplication(@Path('id') String id);

  @POST('/applications/{id}/reject')
  Future<HttpResponse<dynamic>> rejectApplication(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
    @Query('remove_from_pool') bool? removeFromPool,
  );

  @POST('/applications/{id}/calculate-match-score')
  Future<HttpResponse<dynamic>> calculateMatchScore(@Path('id') String id);

  @POST('/applications/rank-all')
  Future<HttpResponse<dynamic>> rankAll();

  // ============================================================================
  // Interviews Endpoints
  // ============================================================================

  @GET('/interviews/')
  Future<List<Interview>> getInterviews({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 100,
    @Query('status') String? status,
    @Query('candidate_id') String? candidateId,
  });

  @GET('/interviews/{id}')
  Future<Interview> getInterview(@Path('id') String id);

  @POST('/interviews/')
  Future<Interview> scheduleInterview(@Body() Map<String, dynamic> data);

  @PUT('/interviews/{id}')
  Future<Interview> updateInterview(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/interviews/{id}/reschedule')
  Future<Interview> rescheduleInterview(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/interviews/{id}/cancel')
  Future<Interview> cancelInterview(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/interviews/{id}/complete')
  Future<Interview> completeInterview(@Path('id') String id);

  @POST('/interviews/{id}/feedback')
  Future<HttpResponse<dynamic>> submitInterviewFeedback(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @GET('/interviews/{id}/feedback')
  Future<HttpResponse<dynamic>> getInterviewFeedback(@Path('id') String id);

  // ============================================================================
  // Offers Endpoints
  // ============================================================================

  @GET('/offers/')
  Future<List<Offer>> getOffers({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 100,
    @Query('status') String? status,
    @Query('candidate_id') String? candidateId,
  });

  @GET('/offers/{id}')
  Future<Offer> getOffer(@Path('id') String id);

  @POST('/offers/')
  Future<Offer> createOffer(@Body() Map<String, dynamic> data);

  @PUT('/offers/{id}')
  Future<Offer> updateOffer(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/offers/{id}/approve')
  Future<Offer> approveOffer(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/offers/{id}/send')
  Future<Offer> sendOffer(@Path('id') String id);

  @POST('/offers/{id}/accept')
  Future<Offer> acceptOffer(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/offers/{id}/revise')
  Future<Offer> reviseOffer(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/offers/{id}/withdraw')
  Future<Offer> withdrawOffer(@Path('id') String id);

  // ============================================================================
  // Dashboard Endpoints - Using HttpResponse for dynamic data
  // ============================================================================

  @GET('/dashboard/pipeline')
  Future<HttpResponse<dynamic>> getPipelineStats();

  @GET('/dashboard/metrics')
  Future<HttpResponse<dynamic>> getDashboardMetrics();

  // ============================================================================
  // Onboarding Endpoints - Using HttpResponse for dynamic data
  // ============================================================================

  @GET('/onboarding/{offer_id}/status')
  Future<HttpResponse<dynamic>> getOnboardingStatus(
      @Path('offer_id') String offerId);

  @POST('/onboarding/tasks')
  Future<HttpResponse<dynamic>> createOnboardingTask(
      @Body() Map<String, dynamic> data);

  @POST('/onboarding/verify')
  Future<HttpResponse<dynamic>> verifyDocument(
      @Body() Map<String, dynamic> data);

  // ============================================================================
  // Referrals Endpoints - Using HttpResponse for dynamic data
  // ============================================================================

  @GET('/referrals/')
  Future<HttpResponse<dynamic>> getReferrals({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 100,
    @Query('status') String? status,
  });

  @GET('/referrals/{id}/status')
  Future<HttpResponse<dynamic>> getReferralStatus(@Path('id') String id);

  @POST('/referrals/')
  Future<HttpResponse<dynamic>> createReferral(
      @Body() Map<String, dynamic> data);

  @POST('/referrals/{id}/approve-bonus')
  Future<HttpResponse<dynamic>> approveReferralBonus(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  // ============================================================================
  // Candidate Portal Endpoints - Using HttpResponse for dynamic data
  // ============================================================================

  @GET('/portal/applications')
  Future<HttpResponse<dynamic>> getMyApplications();

  @GET('/portal/interviews')
  Future<HttpResponse<dynamic>> getMyInterviews();

  @GET('/portal/offers')
  Future<HttpResponse<dynamic>> getMyOffers();

  @GET('/portal/messages')
  Future<HttpResponse<dynamic>> getPortalMessages();

  @POST('/portal/messages')
  Future<HttpResponse<dynamic>> sendPortalMessage(
      @Body() Map<String, dynamic> data);
}
