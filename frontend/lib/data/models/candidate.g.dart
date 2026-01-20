// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Candidate _$CandidateFromJson(Map<String, dynamic> json) => Candidate(
      id: json['id'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      resumeUrl: json['resume_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      portfolioUrl: json['portfolio_url'] as String?,
      skills:
          (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
      totalExperienceYears:
          Candidate._parseDecimal(json['total_experience_years']),
      highestEducation: json['highest_education'] as String?,
      currentCompany: json['current_company'] as String?,
      currentDesignation: json['current_designation'] as String?,
      currentLocation: json['current_location'] as String?,
      preferredLocation: json['preferred_location'] as String?,
      currentCTC: Candidate._parseDecimal(json['current_ctc']),
      expectedCTC: Candidate._parseDecimal(json['expected_ctc']),
      noticePeriodDays: (json['notice_period_days'] as num?)?.toInt(),
      certifications: (json['certifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      isBlacklisted: json['is_blacklisted'] as bool?,
      blacklistReason: json['blacklist_reason'] as String?,
    );

Map<String, dynamic> _$CandidateToJson(Candidate instance) => <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'resume_url': instance.resumeUrl,
      'linkedin_url': instance.linkedinUrl,
      'portfolio_url': instance.portfolioUrl,
      'skills': instance.skills,
      'total_experience_years': instance.totalExperienceYears,
      'highest_education': instance.highestEducation,
      'current_company': instance.currentCompany,
      'current_designation': instance.currentDesignation,
      'current_location': instance.currentLocation,
      'preferred_location': instance.preferredLocation,
      'current_ctc': instance.currentCTC,
      'expected_ctc': instance.expectedCTC,
      'notice_period_days': instance.noticePeriodDays,
      'certifications': instance.certifications,
      'languages': instance.languages,
      'created_at': instance.createdAt?.toIso8601String(),
      'is_blacklisted': instance.isBlacklisted,
      'blacklist_reason': instance.blacklistReason,
    };
