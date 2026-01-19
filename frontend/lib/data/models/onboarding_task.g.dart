// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnboardingTask _$OnboardingTaskFromJson(Map<String, dynamic> json) =>
    OnboardingTask(
      id: (json['id'] as num?)?.toInt(),
      offerId: (json['offer_id'] as num).toInt(),
      taskType: json['task_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'Pending',
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      documentUrl: json['document_url'] as String?,
      verificationStatus: json['verification_status'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OnboardingTaskToJson(OnboardingTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'offer_id': instance.offerId,
      'task_type': instance.taskType,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'due_date': instance.dueDate?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'document_url': instance.documentUrl,
      'verification_status': instance.verificationStatus,
      'created_at': instance.createdAt?.toIso8601String(),
    };
