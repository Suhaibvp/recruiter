import 'package:recruiter_talentbay/features/jobs/services/smart_job_generator.dart';

void main() {
  print('--- Testing SmartJobGenerator ---');

  final cases = [
    {
      'role': 'Senior Flutter Developer',
      'skills': ['Dart', 'Riverpod', 'Firebase'],
    },
    {
      'role': 'Product Manager',
      'skills': ['Agile', 'Jira', 'Roadmap'],
    },
    {
      'role': 'Marketing Specialist',
      'skills': ['SEO', 'Content', 'Social Media'],
    },
    {
      'role': 'Unknown Role',
      'skills': ['Hard Work'],
    },
  ];

  for (var c in cases) {
    print('\nRole: ${c['role']}');
    print('Skills: ${c['skills']}');
    final desc = SmartJobGenerator.generate(
      c['role'] as String,
      c['skills'] as List<String>,
    );
    print(
      'Generated Description Preview:\n${desc.split('\n').take(5).join('\n')}...',
    );
  }
}
