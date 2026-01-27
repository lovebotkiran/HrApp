import 'package:json_annotation/json_annotation.dart';

part 'job_requisition.g.dart';

@JsonSerializable()
class JobRequisition {
  final String? id;
  final String title;
  final String department;
  @JsonKey(name: 'requested_by')
  final String? requestedBy;
  final String status;
  @JsonKey(name: 'employment_type')
  final String? employmentType;
  @JsonKey(name: 'experience_min')
  final int? experienceMin;
  @JsonKey(name: 'required_skills')
  final List<String>? requiredSkills;
  final String? jobDescription;
  final String? location;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  JobRequisition({
    this.id,
    required this.title,
    required this.department,
    this.requestedBy,
    this.status = 'Draft',
    this.employmentType,
    this.experienceMin,
    this.requiredSkills,
    this.jobDescription,
    this.location,
    this.createdAt,
  });

  factory JobRequisition.fromJson(Map<String, dynamic> json) =>
      _$JobRequisitionFromJson(json);
  Map<String, dynamic> toJson() => _$JobRequisitionToJson(this);
}

class JobRequisitionFilter {
  final String? status;
  final String? search;
  final String? department;

  JobRequisitionFilter({this.status, this.search, this.department});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobRequisitionFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          search == other.search &&
          department == other.department;

  @override
  int get hashCode => status.hashCode ^ search.hashCode ^ department.hashCode;
}
