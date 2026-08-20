class JobRulesModel {
  final int minSkillsRequired;
  final bool salaryMandatory;
  final bool companyVerificationRequired;
  final int maxActiveJobsPerCompany;

  JobRulesModel({
    required this.minSkillsRequired,
    required this.salaryMandatory,
    required this.companyVerificationRequired,
    required this.maxActiveJobsPerCompany,
  });

  factory JobRulesModel.fromJson(Map<String, dynamic> json) {
    return JobRulesModel(
      minSkillsRequired: json['minSkillsRequired'] ?? 3,
      salaryMandatory: json['salaryMandatory'] ?? true,
      companyVerificationRequired: json['companyVerificationRequired'] ?? true,
      maxActiveJobsPerCompany: json['maxActiveJobsPerCompany'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minSkillsRequired': minSkillsRequired,
      'salaryMandatory': salaryMandatory,
      'companyVerificationRequired': companyVerificationRequired,
      'maxActiveJobsPerCompany': maxActiveJobsPerCompany,
    };
  }
}
