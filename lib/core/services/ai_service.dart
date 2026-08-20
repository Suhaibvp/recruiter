import 'package:recruiter_talentbay/features/candidates/models/candidate_model.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_model.dart';

class AiRecommendation {
  final double score; // 0 to 100
  final String reason;

  AiRecommendation({required this.score, required this.reason});
}

class AIService {
  // Singleton or Provider-based. For simplicity, static methods or a simple class.
  // In a real app, this might call an external API (Vertex AI, OpenAI, etc.)

  static AiRecommendation evaluate(CandidateModel candidate, JobModel job) {
    double score = 0;
    List<String> reasons = [];

    // 1. Skills Match (40%)
    int matchedSkills = 0;
    if (job.skillsRequired.isNotEmpty) {
      for (var skill in job.skillsRequired) {
        if (candidate.skills.any(
          (s) => s.toLowerCase().contains(skill.toLowerCase()),
        )) {
          matchedSkills++;
        }
      }
      double skillScore = (matchedSkills / job.skillsRequired.length) * 40;
      if (skillScore > 40) skillScore = 40;
      score += skillScore;
      if (matchedSkills > 0) {
        reasons.add(
          'Matches $matchedSkills/${job.skillsRequired.length} skills',
        );
      }
    } else {
      score += 40; // No skills required? Give full points for this section.
    }

    // 2. Experience Match (30%)
    // Check total years of experience vs job requirement
    // Improving this requires calculating total years from candidate.workExperience
    int totalExperienceYears = _calculateTotalExperience(
      candidate.workExperience,
    );
    int requiredMin = job.experienceRequired.minYears;

    if (totalExperienceYears >= requiredMin) {
      score += 30;
      reasons.add('Meets experience requirement ($totalExperienceYears years)');
    } else if (totalExperienceYears > 0) {
      // Partial credit
      double expScore = (totalExperienceYears / requiredMin) * 20;
      score += expScore;
      reasons.add('Has some experience ($totalExperienceYears years)');
    } else {
      reasons.add('No recorded experience');
    }

    // 3. Location Match (20%)
    if (candidate.currentLocation != null) {
      bool cityMatch =
          candidate.currentLocation!.city.toLowerCase() ==
          job.jobLocation.city.toLowerCase();
      bool countryMatch =
          candidate.currentLocation!.country.toLowerCase() ==
          job.jobLocation.country.toLowerCase();

      if (cityMatch) {
        score += 20;
        reasons.add('Located in ${candidate.currentLocation!.city}');
      } else if (countryMatch) {
        score += 10;
        reasons.add('Located in same country');
      } else if (candidate.willingToRelocate) {
        score += 10;
        reasons.add('Willing to relocate');
      }
    }

    // 4. Remote/Work Mode Fit (10%)
    // Simple check if job is remote
    bool isRemoteJob = job.workMode.toLowerCase().contains('remote');
    if (isRemoteJob) {
      score += 10;
      reasons.add('Remote job fit');
    } else {
      // If not remote, and location matches, we already gave points.
      // Let's give points if they are in the same city.
      if (candidate.currentLocation?.city.toLowerCase() ==
          job.jobLocation.city.toLowerCase()) {
        score += 10;
      }
    }

    return AiRecommendation(
      score: score.clamp(0, 100),
      reason: reasons.isNotEmpty ? reasons.join('. ') : 'Profile reviewed.',
    );
  }

  static int _calculateTotalExperience(List<WorkExperience> experience) {
    int totalDays = 0;
    for (var exp in experience) {
      final end = exp.endDate ?? DateTime.now();
      totalDays += end.difference(exp.startDate).inDays;
    }
    return (totalDays / 365).floor();
  }
}
