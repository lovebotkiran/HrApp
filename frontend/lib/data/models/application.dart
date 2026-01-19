import 'package:json_annotation/json_annotation.dart';

part 'application.g.dart';

@JsonSerializable()
class Application {
  final int? id;
  @JsonKey(name: 'application_number')
  final String? applicationNumber;
  @JsonKey(name: 'candidate_id')
  final int candidateId;
  @JsonKey(name: 'job_posting_id')
  final int jobPostingId;
  final String status;
  final String? source;
  @JsonKey(name: 'cover_letter')
  final String? coverLetter;
  @JsonKey(name: 'applied_at')
  final DateTime? appliedAt;
  @JsonKey(name: 'match_score')
  final double? matchScore;
  @JsonKey(name: 'resume_url')
  final String? resumeUrl;
  @JsonKey(name: 'candidate_name')
  final String? candidateName;
  @JsonKey(name: 'candidate_email')
  final String? candidateEmail;
  @JsonKey(name: 'job_title')
  final String? jobTitle;

  Application({
    this.id,
    this.applicationNumber,
    required this.candidateId,
    required this.jobPostingId,
    this.status = 'New',
    this.source,
    this.coverLetter,
    this.appliedAt,
    this.matchScore,
    this.resumeUrl,
    this.candidateName,
    this.candidateEmail,
    this.jobTitle,
  });

  factory Application.fromJson(Map<String, dynamic> json) => _$ApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationToJson(this);
}
