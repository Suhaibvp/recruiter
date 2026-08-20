class RoleMasterModel {
  final String roleId;
  final String roleName;
  final bool isActive;

  RoleMasterModel({
    required this.roleId,
    required this.roleName,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {'roleId': roleId, 'roleName': roleName, 'isActive': isActive};
  }

  factory RoleMasterModel.fromMap(Map<String, dynamic> map) {
    return RoleMasterModel(
      roleId: map['roleId'] ?? '',
      roleName: map['roleName'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

class DesignationMasterModel {
  final String designationId;
  final String roleId;
  final String designationName;
  final List<String> defaultSkills;
  final bool isActive;

  DesignationMasterModel({
    required this.designationId,
    required this.roleId,
    required this.designationName,
    required this.defaultSkills,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'designationId': designationId,
      'roleId': roleId,
      'designationName': designationName,
      'defaultSkills': defaultSkills,
      'isActive': isActive,
    };
  }

  factory DesignationMasterModel.fromMap(Map<String, dynamic> map) {
    return DesignationMasterModel(
      designationId: map['designationId'] ?? '',
      roleId: map['roleId'] ?? '',
      designationName: map['designationName'] ?? '',
      defaultSkills: List<String>.from(map['defaultSkills'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }
}
