import 'package:json_annotation/json_annotation.dart';

part 'application.g.dart';

@JsonSerializable()
class Application {
  final String? id;
  @JsonKey(name: 'application_number')
  final String? applicationNumber;
  @JsonKey(name: 'candidate_id')
  final String candidateId;
  @JsonKey(name: 'job_posting_id')
  final String jobPostingId;
  final String status;
  final String? source;
  @JsonKey(name: 'cover_letter')
  final String? coverLetter;
  @JsonKey(name: 'applied_at')
  final DateTime? appliedAt;
  @JsonKey(name: 'resume_url')
  final String? resumeUrl;
  @JsonKey(name: 'ai_match_score', fromJson: _parseScore)
  final double? aiMatchScore;

  static double? _parseScore(dynamic score) {
    if (score == null) return null;
    if (score is num) return score.toDouble();
    if (score is String) return double.tryParse(score);
    return null;
  }

  @JsonKey(name: 'ai_match_reasoning')
  final String? aiMatchReasoning;
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
    this.resumeUrl,
    this.aiMatchScore,
    this.aiMatchReasoning,
    this.candidateName,
    this.candidateEmail,
    this.jobTitle,
  });

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationToJson(this);
}

class ApplicationFilter {
  final String? status;
  final String? jobPostingId;

  ApplicationFilter({this.status, this.jobPostingId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          jobPostingId == other.jobPostingId;

  @override
  int get hashCode => status.hashCode ^ jobPostingId.hashCode;
}
