// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_requisition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobRequisition _$JobRequisitionFromJson(Map<String, dynamic> json) =>
    JobRequisition(
      id: json['id'] as String?,
      title: json['title'] as String,
      department: json['department'] as String,
      requestedBy: json['requested_by'] as String?,
      status: json['status'] as String? ?? 'Draft',
      employmentType: json['employment_type'] as String?,
      experienceMin: (json['experience_min'] as num?)?.toInt(),
      requiredSkills: (json['required_skills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      jobDescription: json['job_description'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$JobRequisitionToJson(JobRequisition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'department': instance.department,
      'requested_by': instance.requestedBy,
      'status': instance.status,
      'employment_type': instance.employmentType,
      'experience_min': instance.experienceMin,
      'required_skills': instance.requiredSkills,
      'job_description': instance.jobDescription,
      'created_at': instance.createdAt?.toIso8601String(),
    };
