// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Candidate _$CandidateFromJson(Map<String, dynamic> json) => Candidate(
<<<<<<< HEAD
      id: (json['id'] as num?)?.toInt(),
=======
      id: json['id'] as String?,
>>>>>>> origin/main
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      resumeUrl: json['resume_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      portfolioUrl: json['portfolio_url'] as String?,
<<<<<<< HEAD
      skills: json['skills'] as String?,
      experience: json['experience'] as String?,
      education: json['education'] as String?,
=======
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
      experience: json['experience'] as String?,
      education: json['education'] as String?,
      certifications: (json['certifications'] as List<dynamic>?)?.map((e) => e as String).toList(),
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList(),
>>>>>>> origin/main
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
<<<<<<< HEAD
=======
      'certifications': instance.certifications,
      'languages': instance.languages,
>>>>>>> origin/main
      'created_at': instance.createdAt?.toIso8601String(),
    };
