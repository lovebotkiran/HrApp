import 'package:json_annotation/json_annotation.dart';

part 'department_skill.g.dart';

@JsonSerializable()
class DepartmentSkill {
  final String? id;
  final String department;
  @JsonKey(name: 'skill_name')
  final String skillName;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  DepartmentSkill({
    this.id,
    required this.department,
    required this.skillName,
    this.createdAt,
  });

  factory DepartmentSkill.fromJson(Map<String, dynamic> json) =>
      _$DepartmentSkillFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentSkillToJson(this);
}
