// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Referral _$ReferralFromJson(Map<String, dynamic> json) => Referral(
<<<<<<< HEAD
      id: (json['id'] as num?)?.toInt(),
      referrerId: (json['referrer_id'] as num).toInt(),
=======
      id: json['id'] as String?,
      referrerId: json['referrer_id'] as String,
>>>>>>> origin/main
      candidateName: json['candidate_name'] as String,
      candidateEmail: json['candidate_email'] as String,
      candidatePhone: json['candidate_phone'] as String?,
      position: json['position'] as String,
      status: json['status'] as String? ?? 'Pending',
      referralCode: json['referral_code'] as String?,
      bonusAmount: (json['bonus_amount'] as num?)?.toDouble(),
      bonusStatus: json['bonus_status'] as String?,
      referrerName: json['referrer_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ReferralToJson(Referral instance) => <String, dynamic>{
      'id': instance.id,
      'referrer_id': instance.referrerId,
      'candidate_name': instance.candidateName,
      'candidate_email': instance.candidateEmail,
      'candidate_phone': instance.candidatePhone,
      'position': instance.position,
      'status': instance.status,
      'referral_code': instance.referralCode,
      'bonus_amount': instance.bonusAmount,
      'bonus_status': instance.bonusStatus,
      'referrer_name': instance.referrerName,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
