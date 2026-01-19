import 'package:json_annotation/json_annotation.dart';

part 'referral.g.dart';

@JsonSerializable()
class Referral {
<<<<<<< HEAD
  final int? id;
  @JsonKey(name: 'referrer_id')
  final int referrerId;
=======
  final String? id;
  @JsonKey(name: 'referrer_id')
  final String referrerId;
>>>>>>> origin/main
  @JsonKey(name: 'candidate_name')
  final String candidateName;
  @JsonKey(name: 'candidate_email')
  final String candidateEmail;
  @JsonKey(name: 'candidate_phone')
  final String? candidatePhone;
  final String position;
  final String status;
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  @JsonKey(name: 'bonus_amount')
  final double? bonusAmount;
  @JsonKey(name: 'bonus_status')
  final String? bonusStatus;
  @JsonKey(name: 'referrer_name')
  final String? referrerName;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Referral({
    this.id,
    required this.referrerId,
    required this.candidateName,
    required this.candidateEmail,
    this.candidatePhone,
    required this.position,
    this.status = 'Pending',
    this.referralCode,
    this.bonusAmount,
    this.bonusStatus,
    this.referrerName,
    this.createdAt,
    this.updatedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) => _$ReferralFromJson(json);
  Map<String, dynamic> toJson() => _$ReferralToJson(this);
}
