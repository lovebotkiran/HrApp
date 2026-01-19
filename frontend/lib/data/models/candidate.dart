import 'package:json_annotation/json_annotation.dart';

part 'candidate.g.dart';

@JsonSerializable()
class Candidate {
  final int? id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String email;
  final String? phone;
  @JsonKey(name: 'resume_url')
  final String? resumeUrl;
  @JsonKey(name: 'linkedin_url')
  final String? linkedinUrl;
  @JsonKey(name: 'portfolio_url')
  final String? portfolioUrl;
  final String? skills;
  final String? experience;
  final String? education;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Candidate({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.resumeUrl,
    this.linkedinUrl,
    this.portfolioUrl,
    this.skills,
    this.experience,
    this.education,
    this.createdAt,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => _$CandidateFromJson(json);
  Map<String, dynamic> toJson() => _$CandidateToJson(this);
}
