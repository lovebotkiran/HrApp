import 'package:json_annotation/json_annotation.dart';

part 'dashboard_metrics.g.dart';

@JsonSerializable()
class DashboardMetrics {
  @JsonKey(name: 'total_applications')
  final int totalApplications;
  @JsonKey(name: 'active_jobs')
  final int activeJobs;
  @JsonKey(name: 'interviews_scheduled')
  final int interviewsScheduled;
  @JsonKey(name: 'offers_sent')
  final int offersSent;
  @JsonKey(name: 'applications_change')
  final double? applicationsChange;
  @JsonKey(name: 'jobs_change')
  final double? jobsChange;
  @JsonKey(name: 'interviews_change')
  final double? interviewsChange;
  @JsonKey(name: 'offers_change')
  final double? offersChange;

  DashboardMetrics({
    required this.totalApplications,
    required this.activeJobs,
    required this.interviewsScheduled,
    required this.offersSent,
    this.applicationsChange,
    this.jobsChange,
    this.interviewsChange,
    this.offersChange,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) => _$DashboardMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardMetricsToJson(this);
}

@JsonSerializable()
class PipelineStats {
  final int applied;
  final int screening;
  final int shortlisted;
  final int interview;
  final int selected;
  final int offered;
  final int onboarded;

  PipelineStats({
    required this.applied,
    required this.screening,
    required this.shortlisted,
    required this.interview,
    required this.selected,
    required this.offered,
    required this.onboarded,
  });

  factory PipelineStats.fromJson(Map<String, dynamic> json) => _$PipelineStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PipelineStatsToJson(this);

  Map<String, int> toMap() {
    return {
      'Applied': applied,
      'Screening': screening,
      'Shortlisted': shortlisted,
      'Interview': interview,
      'Selected': selected,
      'Offered': offered,
      'Onboarded': onboarded,
    };
  }
}
