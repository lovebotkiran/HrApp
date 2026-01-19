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
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
      experience: json['experience'] as String?,
      education: json['education'] as String?,
      certifications: (json['certifications'] as List<dynamic>?)?.map((e) => e as String).toList(),
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
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
      'experience': instance.experience,
      'education': instance.education,
      'certifications': instance.certifications,
      'languages': instance.languages,
      'created_at': instance.createdAt?.toIso8601String(),
    };
