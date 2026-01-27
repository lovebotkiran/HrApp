import 'package:json_annotation/json_annotation.dart';

part 'candidate.g.dart';

@JsonSerializable()
class Candidate {
  final String? id;
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
  final List<String>? skills;
  @JsonKey(name: 'total_experience_years', fromJson: _parseDecimal)
  final double? totalExperienceYears;
  @JsonKey(name: 'highest_education')
  final String? highestEducation;
  @JsonKey(name: 'current_company')
  final String? currentCompany;
  @JsonKey(name: 'current_designation')
  final String? currentDesignation;
  @JsonKey(name: 'current_location')
  final String? currentLocation;
  @JsonKey(name: 'preferred_location')
  final String? preferredLocation;
  @JsonKey(name: 'current_ctc', fromJson: _parseDecimal)
  final double? currentCTC;
  @JsonKey(name: 'expected_ctc', fromJson: _parseDecimal)
  final double? expectedCTC;
  @JsonKey(name: 'notice_period_days')
  final int? noticePeriodDays;
  final List<String>? certifications;
  final List<String>? languages;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'is_blacklisted')
  final bool? isBlacklisted;
  @JsonKey(name: 'blacklist_reason')
  final String? blacklistReason;
  @JsonKey(name: 'is_active')
  final bool? isActive;

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
    this.totalExperienceYears,
    this.highestEducation,
    this.currentCompany,
    this.currentDesignation,
    this.currentLocation,
    this.preferredLocation,
    this.currentCTC,
    this.expectedCTC,
    this.noticePeriodDays,
    this.certifications,
    this.languages,
    this.createdAt,
    this.isBlacklisted,
    this.blacklistReason,
    this.isActive,
  });

  static double? _parseDecimal(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory Candidate.fromJson(Map<String, dynamic> json) =>
      _$CandidateFromJson(json);
  Map<String, dynamic> toJson() => _$CandidateToJson(this);
}
