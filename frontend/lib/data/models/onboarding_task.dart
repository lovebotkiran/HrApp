import 'package:json_annotation/json_annotation.dart';

part 'onboarding_task.g.dart';

@JsonSerializable()
class OnboardingTask {
  final int? id;
  @JsonKey(name: 'offer_id')
  final int offerId;
  @JsonKey(name: 'task_type')
  final String taskType;
  final String title;
  final String? description;
  final String status;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @JsonKey(name: 'document_url')
  final String? documentUrl;
  @JsonKey(name: 'verification_status')
  final String? verificationStatus;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  OnboardingTask({
    this.id,
    required this.offerId,
    required this.taskType,
    required this.title,
    this.description,
    this.status = 'Pending',
    this.dueDate,
    this.completedAt,
    this.documentUrl,
    this.verificationStatus,
    this.createdAt,
  });

  factory OnboardingTask.fromJson(Map<String, dynamic> json) => _$OnboardingTaskFromJson(json);
  Map<String, dynamic> toJson() => _$OnboardingTaskToJson(this);
}
