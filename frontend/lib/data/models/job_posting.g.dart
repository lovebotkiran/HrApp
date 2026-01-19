// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_posting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobPosting _$JobPostingFromJson(Map<String, dynamic> json) => JobPosting(
      id: json['id'] as String?,
      jobCode: json['job_code'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      requirements: json['requirements'] as String?,
      location: json['location'] as String?,
      employmentType: json['employment_type'] as String?,
      salaryRange: json['salary_range'] as String?,
      status: json['status'] as String? ?? 'Draft',
      postedDate: json['posted_date'] == null
          ? null
          : DateTime.parse(json['posted_date'] as String),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(json['expiry_date'] as String),
      viewsCount: (json['views_count'] as num?)?.toInt(),
      applicationsCount: (json['applications_count'] as num?)?.toInt(),
      jobRequisitionId: json['job_requisition_id'] as String?,
<<<<<<< HEAD
=======
      skillsRequired: (json['skills_required'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
>>>>>>> origin/main
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$JobPostingToJson(JobPosting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'job_code': instance.jobCode,
      'title': instance.title,
      'description': instance.description,
      'requirements': instance.requirements,
      'location': instance.location,
      'employment_type': instance.employmentType,
      'salary_range': instance.salaryRange,
      'status': instance.status,
      'posted_date': instance.postedDate?.toIso8601String(),
      'expiry_date': instance.expiryDate?.toIso8601String(),
      'views_count': instance.viewsCount,
      'applications_count': instance.applicationsCount,
      'job_requisition_id': instance.jobRequisitionId,
<<<<<<< HEAD
=======
      'skills_required': instance.skillsRequired,
>>>>>>> origin/main
      'created_at': instance.createdAt?.toIso8601String(),
    };
