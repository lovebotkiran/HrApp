// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardMetrics _$DashboardMetricsFromJson(Map<String, dynamic> json) =>
    DashboardMetrics(
      totalApplications: (json['total_applications'] as num).toInt(),
      activeJobs: (json['active_jobs'] as num).toInt(),
      interviewsScheduled: (json['interviews_scheduled'] as num).toInt(),
      offersSent: (json['offers_sent'] as num).toInt(),
      applicationsChange: (json['applications_change'] as num?)?.toDouble(),
      jobsChange: (json['jobs_change'] as num?)?.toDouble(),
      interviewsChange: (json['interviews_change'] as num?)?.toDouble(),
      offersChange: (json['offers_change'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$DashboardMetricsToJson(DashboardMetrics instance) =>
    <String, dynamic>{
      'total_applications': instance.totalApplications,
      'active_jobs': instance.activeJobs,
      'interviews_scheduled': instance.interviewsScheduled,
      'offers_sent': instance.offersSent,
      'applications_change': instance.applicationsChange,
      'jobs_change': instance.jobsChange,
      'interviews_change': instance.interviewsChange,
      'offers_change': instance.offersChange,
    };

PipelineStats _$PipelineStatsFromJson(Map<String, dynamic> json) =>
    PipelineStats(
      applied: (json['applied'] as num).toInt(),
      screening: (json['screening'] as num).toInt(),
      shortlisted: (json['shortlisted'] as num).toInt(),
      interview: (json['interview'] as num).toInt(),
      selected: (json['selected'] as num).toInt(),
      offered: (json['offered'] as num).toInt(),
      onboarded: (json['onboarded'] as num).toInt(),
    );

Map<String, dynamic> _$PipelineStatsToJson(PipelineStats instance) =>
    <String, dynamic>{
      'applied': instance.applied,
      'screening': instance.screening,
      'shortlisted': instance.shortlisted,
      'interview': instance.interview,
      'selected': instance.selected,
      'offered': instance.offered,
      'onboarded': instance.onboarded,
    };
