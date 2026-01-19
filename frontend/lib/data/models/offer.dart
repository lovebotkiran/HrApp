import 'package:json_annotation/json_annotation.dart';

part 'offer.g.dart';

@JsonSerializable()
class Offer {
<<<<<<< HEAD
  final int? id;
  @JsonKey(name: 'application_id')
  final int applicationId;
=======
  final String? id;
  @JsonKey(name: 'application_id')
  final String applicationId;
>>>>>>> origin/main
  @JsonKey(name: 'base_salary')
  final double baseSalary;
  final double? bonus;
  @JsonKey(name: 'stock_options')
  final double? stockOptions;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'expiration_date')
  final DateTime expirationDate;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Offer({
    this.id,
    required this.applicationId,
    required this.baseSalary,
    this.bonus,
    this.stockOptions,
    required this.startDate,
    required this.expirationDate,
    this.status = 'Draft',
    this.createdAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
  Map<String, dynamic> toJson() => _$OfferToJson(this);
}
