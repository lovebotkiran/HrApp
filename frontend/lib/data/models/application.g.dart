// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Application _$ApplicationFromJson(Map<String, dynamic> json) => Application(
      id: (json['id'] as num?)?.toInt(),
      applicationNumber: json['application_number'] as String?,
      candidateId: (json['candidate_id'] as num).toInt(),
      jobPostingId: (json['job_posting_id'] as num).toInt(),
      status: json['status'] as String? ?? 'New',
      source: json['source'] as String?,
      coverLetter: json['cover_letter'] as String?,
      appliedAt: json['applied_at'] == null
          ? null
          : DateTime.parse(json['applied_at'] as String),
      matchScore: (json['match_score'] as num?)?.toDouble(),
      resumeUrl: json['resume_url'] as String?,
      candidateName: json['candidate_name'] as String?,
      candidateEmail: json['candidate_email'] as String?,
      jobTitle: json['job_title'] as String?,
    );

Map<String, dynamic> _$ApplicationToJson(Application instance) =>
    <String, dynamic>{
      'id': instance.id,
      'application_number': instance.applicationNumber,
      'candidate_id': instance.candidateId,
      'job_posting_id': instance.jobPostingId,
      'status': instance.status,
      'source': instance.source,
      'cover_letter': instance.coverLetter,
      'applied_at': instance.appliedAt?.toIso8601String(),
      'match_score': instance.matchScore,
      'resume_url': instance.resumeUrl,
      'candidate_name': instance.candidateName,
      'candidate_email': instance.candidateEmail,
      'job_title': instance.jobTitle,
    };
