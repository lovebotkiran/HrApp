import 'package:json_annotation/json_annotation.dart';

part 'interview.g.dart';

@JsonSerializable()
class Interview {
  final String? id;
  @JsonKey(name: 'application_id')
  final String applicationId;
  @JsonKey(name: 'interviewer_id')
  final String? interviewerId; // Made nullable
  @JsonKey(name: 'scheduled_date') // Mapped to scheduled_date
  final DateTime scheduledTime;
  @JsonKey(name: 'duration_minutes') // Mapped to duration_minutes
  final int duration;
  @JsonKey(name: 'interview_type')
  final String interviewType;
  final String status;
  @JsonKey(name: 'video_link') // Mapped to video_link
  final String? meetingLink;
  final String? feedback;
  final int? rating;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Interview({
    this.id,
    required this.applicationId,
    this.interviewerId, // Made optional
    required this.scheduledTime,
    this.duration = 60,
    this.interviewType = 'Technical',
    this.status = 'Scheduled',
    this.meetingLink,
    this.feedback,
    this.rating,
    this.createdAt,
  });

  factory Interview.fromJson(Map<String, dynamic> json) =>
      _$InterviewFromJson(json);
  Map<String, dynamic> toJson() => _$InterviewToJson(this);
}
