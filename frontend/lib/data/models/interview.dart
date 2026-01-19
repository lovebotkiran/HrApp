import 'package:json_annotation/json_annotation.dart';

part 'interview.g.dart';

@JsonSerializable()
class Interview {
<<<<<<< HEAD
  final int? id;
  @JsonKey(name: 'application_id')
  final int applicationId;
  @JsonKey(name: 'interviewer_id')
  final int interviewerId;
=======
  final String? id;
  @JsonKey(name: 'application_id')
  final String applicationId;
  @JsonKey(name: 'interviewer_id')
  final String interviewerId;
>>>>>>> origin/main
  @JsonKey(name: 'scheduled_time')
  final DateTime scheduledTime;
  final int duration;
  @JsonKey(name: 'interview_type')
  final String interviewType;
  final String status;
  @JsonKey(name: 'meeting_link')
  final String? meetingLink;
  final String? feedback;
  final int? rating;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Interview({
    this.id,
    required this.applicationId,
    required this.interviewerId,
    required this.scheduledTime,
    this.duration = 60,
    this.interviewType = 'Technical',
    this.status = 'Scheduled',
    this.meetingLink,
    this.feedback,
    this.rating,
    this.createdAt,
  });

  factory Interview.fromJson(Map<String, dynamic> json) => _$InterviewFromJson(json);
  Map<String, dynamic> toJson() => _$InterviewToJson(this);
}
