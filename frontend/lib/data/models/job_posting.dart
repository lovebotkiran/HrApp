import 'package:json_annotation/json_annotation.dart';

part 'job_posting.g.dart';

@JsonSerializable()
class JobPosting {
  final String? id;
  @JsonKey(name: 'job_code')
  final String? jobCode;
  final String title;
  final String description;
  final String? requirements;
  final String? location;
  @JsonKey(name: 'employment_type')
  final String? employmentType;
  @JsonKey(name: 'salary_range')
  final String? salaryRange;
  final String status;
  @JsonKey(name: 'posted_date')
  final DateTime? postedDate;
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  @JsonKey(name: 'views_count')
  final int? viewsCount;
  @JsonKey(name: 'applications_count')
  final int? applicationsCount;
  @JsonKey(name: 'job_requisition_id')
  final String? jobRequisitionId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  JobPosting({
    this.id,
    this.jobCode,
    required this.title,
    required this.description,
    this.requirements,
    this.location,
    this.employmentType,
    this.salaryRange,
    this.status = 'Draft',
    this.postedDate,
    this.expiryDate,
    this.viewsCount,
    this.applicationsCount,
    this.jobRequisitionId,
    this.createdAt,
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) => _$JobPostingFromJson(json);
  Map<String, dynamic> toJson() => _$JobPostingToJson(this);
}
