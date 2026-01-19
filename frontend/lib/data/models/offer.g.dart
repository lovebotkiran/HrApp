// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offer _$OfferFromJson(Map<String, dynamic> json) => Offer(
      id: json['id'] as String?,
      applicationId: json['application_id'] as String,
      baseSalary: (json['base_salary'] as num).toDouble(),
      bonus: (json['bonus'] as num?)?.toDouble(),
      stockOptions: (json['stock_options'] as num?)?.toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      expirationDate: DateTime.parse(json['expiration_date'] as String),
      status: json['status'] as String? ?? 'Draft',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
      'id': instance.id,
      'application_id': instance.applicationId,
      'base_salary': instance.baseSalary,
      'bonus': instance.bonus,
      'stock_options': instance.stockOptions,
      'start_date': instance.startDate.toIso8601String(),
      'expiration_date': instance.expirationDate.toIso8601String(),
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
    };
