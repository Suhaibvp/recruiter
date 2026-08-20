import 'package:cloud_firestore/cloud_firestore.dart';

class CandidateModel {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final DateTime createdAt;

  // Basic Personal Info
  final DateTime? dob;
  final String? gender;
  final Address? currentLocation;
  final String? nationality;
  final bool willingToRelocate;

  // Professional Summary
  final String? bio; // Headline
  final String? aboutMe;

  // Job Preferences (Simplified as dynamic or specific class if needed, using Map for now or we can copy classes)
  // For the recruiter app, we can simplify and just display what's needed or copy the classes.
  // Let's copy the essential structure using inner classes or maps.
  // Or better, define them here.

  final JobPreference? jobPreference;

  // Skills
  final List<String>
  skills; // Simplified list of skill names usually enough for display

  // Experience
  final List<WorkExperience> workExperience;

  // Education
  final List<Education> education;

  // Projects
  final List<Project> projects;

  // Certifications
  final List<Certification> certifications;

  // Resume & Portfolio
  final String? resumeUrl;
  final String? portfolioUrl;
  final String? githubProfile;
  final String? linkedinProfile;
  final List<String> otherLinks;

  // Additional Info
  final Map<String, String> languages; // Language: Proficiency
  final String? achievements;
  final String? disabilityInfo;

  // System Fields
  final double profileCompletionPercentage;
  final bool isProfilePublic;
  final String accountStatus; // Active, Blocked
  final DateTime lastUpdated;

  String get fullName => '$firstName $lastName'.trim();

  CandidateModel({
    required this.uid,
    required this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.photoUrl,
    required this.createdAt,
    this.dob,
    this.gender,
    this.currentLocation,
    this.nationality,
    this.willingToRelocate = false,
    this.bio,
    this.aboutMe,
    this.jobPreference,
    this.skills = const [],
    this.workExperience = const [],
    this.education = const [],
    this.projects = const [],
    this.certifications = const [],
    this.resumeUrl,
    this.portfolioUrl,
    this.githubProfile,
    this.linkedinProfile,
    this.otherLinks = const [],
    this.languages = const {},
    this.achievements,
    this.disabilityInfo,
    this.profileCompletionPercentage = 0.0,
    this.isProfilePublic = true,
    this.accountStatus = 'Active',
    required this.lastUpdated,
  });

  factory CandidateModel.fromMap(Map<String, dynamic> map) {
    return CandidateModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dob: map['dob'] != null
          ? (map['dob'] is String ? DateTime.tryParse(map['dob']) : null)
          : null,
      gender: map['gender'],
      currentLocation: map['currentLocation'] != null
          ? Address.fromMap(map['currentLocation'])
          : null,
      nationality: map['nationality'],
      willingToRelocate: map['willingToRelocate'] ?? false,
      bio: map['bio'],
      aboutMe: map['aboutMe'],
      jobPreference: map['jobPreference'] != null
          ? JobPreference.fromMap(map['jobPreference'])
          : null,
      skills: List<String>.from(
        (map['skills'] as List? ?? []).map(
          (x) => x is Map ? x['name'] ?? '' : x.toString(),
        ),
      ),
      workExperience: List<WorkExperience>.from(
        (map['workExperience'] as List? ?? []).map(
          (x) => WorkExperience.fromMap(x),
        ),
      ),
      education: List<Education>.from(
        (map['education'] as List? ?? []).map((x) => Education.fromMap(x)),
      ),
      projects: List<Project>.from(
        (map['projects'] as List? ?? []).map((x) => Project.fromMap(x)),
      ),
      certifications: List<Certification>.from(
        (map['certifications'] as List? ?? []).map(
          (x) => Certification.fromMap(x),
        ),
      ),
      resumeUrl: map['resumeUrl'],
      portfolioUrl: map['portfolioUrl'],
      githubProfile: map['githubProfile'],
      linkedinProfile: map['linkedinProfile'],
      otherLinks: List<String>.from(map['otherLinks'] ?? []),
      languages: Map<String, String>.from(map['languages'] ?? {}),
      achievements: map['achievements'],
      disabilityInfo: map['disabilityInfo'],
      profileCompletionPercentage: (map['profileCompletionPercentage'] ?? 0.0)
          .toDouble(),
      isProfilePublic: map['isProfilePublic'] ?? true,
      accountStatus: map['accountStatus'] ?? 'Active',
      lastUpdated: map['lastUpdated'] is String
          ? DateTime.tryParse(map['lastUpdated']) ?? DateTime.now()
          : (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Address {
  final String city;
  final String country;
  final String? state;

  Address({required this.city, required this.country, this.state});

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      state: map['state'],
    );
  }
}

class JobPreference {
  final List<String> preferredRoles;
  final List<String> preferredLocations;
  final String? preferredIndustry;
  final String? expectedSalary; // e.g. "50k-70k USD"

  JobPreference({
    required this.preferredRoles,
    required this.preferredLocations,
    this.preferredIndustry,
    this.expectedSalary,
  });

  factory JobPreference.fromMap(Map<String, dynamic> map) {
    // Handle mismatch with Candidate App structure

    // 1. Roles: Candidate App sends 'role' (String), Recruiter App expects 'preferredRoles' (List)
    List<String> roles = [];
    if (map['preferredRoles'] != null) {
      roles = List<String>.from(map['preferredRoles']);
    } else if (map['role'] != null) {
      roles = [map['role'] as String];
    }

    // 2. Locations: Candidate App sends 'preferredLocations' (List), Recruiter App expects 'preferredLocations' (List) - Match
    List<String> locations = List<String>.from(map['preferredLocations'] ?? []);

    // 3. Salary: Candidate App sends 'salaryMin' (double) & 'salaryMax' (double), Recruiter App expects 'expectedSalary' (String)
    String? salary;
    if (map['expectedSalary'] != null) {
      salary = map['expectedSalary'].toString();
    } else if (map['salaryMin'] != null || map['salaryMax'] != null) {
      final min = map['salaryMin'] ?? 0;
      final max = map['salaryMax'] ?? 0;
      final currency = map['salaryCurrency'] ?? '';
      salary = '$currency $min - $max';
    }

    return JobPreference(
      preferredRoles: roles,
      preferredLocations: locations,
      preferredIndustry:
          map['preferredIndustry'], // Might be missing in Candidate App, that's fine
      expectedSalary: salary,
    );
  }
}

class WorkExperience {
  final String jobTitle;
  final String companyName;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

  WorkExperience({
    required this.jobTitle,
    required this.companyName,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
  });

  factory WorkExperience.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return WorkExperience(
      jobTitle: map['jobTitle'] ?? '',
      companyName: map['companyName'] ?? '',
      startDate: parseDate(map['startDate']) ?? DateTime.now(),
      endDate: parseDate(map['endDate']),
      isCurrent: map['isCurrent'] ?? false,
      description: map['description'],
    );
  }
}

class Education {
  final String school;
  final String degree;
  final String fieldOfStudy;
  final DateTime startDate;
  final DateTime? endDate;

  Education({
    required this.school,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
  });

  factory Education.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Education(
      school: map['schoolName'] ?? map['school'] ?? '', // Handle variations
      degree: map['degree'] ?? '',
      fieldOfStudy: map['fieldOfStudy'] ?? '',
      startDate: parseDate(map['startDate']) ?? DateTime.now(),
      endDate: parseDate(map['endDate']),
    );
  }
}

class Project {
  final String title;
  final String description;
  final List<String> technologies;
  final String? link;

  Project({
    required this.title,
    required this.description,
    required this.technologies,
    this.link,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      technologies: List<String>.from(
        map['technologies'] ?? map['techStack'] ?? [],
      ),
      link: map['link'] ?? map['url'],
    );
  }
}

class Certification {
  final String name;
  final String issuingOrganization;
  final DateTime issueDate;
  final String? credentialUrl;

  Certification({
    required this.name,
    required this.issuingOrganization,
    required this.issueDate,
    this.credentialUrl,
  });

  factory Certification.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Certification(
      name: map['name'] ?? '',
      issuingOrganization: map['issuingOrganization'] ?? '',
      issueDate: parseDate(map['issueDate']) ?? DateTime.now(),
      credentialUrl: map['credentialUrl'],
    );
  }
}
