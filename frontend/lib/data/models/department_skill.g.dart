// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department_skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepartmentSkill _$DepartmentSkillFromJson(Map<String, dynamic> json) =>
    DepartmentSkill(
      id: json['id'] as String?,
      department: json['department'] as String,
      skillName: json['skill_name'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DepartmentSkillToJson(DepartmentSkill instance) =>
    <String, dynamic>{
      'id': instance.id,
      'department': instance.department,
      'skill_name': instance.skillName,
      'created_at': instance.createdAt?.toIso8601String(),
    };
