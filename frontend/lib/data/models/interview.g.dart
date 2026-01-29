// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Interview _$InterviewFromJson(Map<String, dynamic> json) => Interview(
      id: json['id'] as String?,
      applicationId: json['application_id'] as String,
      interviewerId: json['interviewer_id'] as String?,
      scheduledTime: DateTime.parse(json['scheduled_date'] as String),
      duration: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      interviewType: json['interview_type'] as String? ?? 'Technical',
      status: json['status'] as String? ?? 'Scheduled',
      meetingLink: json['video_link'] as String?,
      feedback: json['feedback'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$InterviewToJson(Interview instance) => <String, dynamic>{
      'id': instance.id,
      'application_id': instance.applicationId,
      'interviewer_id': instance.interviewerId,
      'scheduled_date': instance.scheduledTime.toIso8601String(),
      'duration_minutes': instance.duration,
      'interview_type': instance.interviewType,
      'status': instance.status,
      'video_link': instance.meetingLink,
      'feedback': instance.feedback,
      'rating': instance.rating,
      'created_at': instance.createdAt?.toIso8601String(),
    };
