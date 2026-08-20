class SmartJobGenerator {
  static String generate(String role, List<String> skills) {
    final normalizedRole = role.toLowerCase();
    final template = _findTemplate(normalizedRole);

    return _fillTemplate(template, role, skills);
  }

  static JobTemplate _findTemplate(String role) {
    if (role.contains('flutter') ||
        role.contains('mobile') ||
        role.contains('android') ||
        role.contains('ios')) {
      return _mobileDevTemplate;
    } else if (role.contains('backend') ||
        role.contains('node') ||
        role.contains('java') ||
        role.contains('python')) {
      return _backendDevTemplate;
    } else if (role.contains('frontend') ||
        role.contains('react') ||
        role.contains('web') ||
        role.contains('angular')) {
      return _frontendDevTemplate;
    } else if (role.contains('ui') ||
        role.contains('ux') ||
        role.contains('designer')) {
      return _designerTemplate;
    } else if (role.contains('product manager') ||
        role.contains('manager') ||
        role.contains('owner')) {
      return _productManagerTemplate;
    } else if (role.contains('data') ||
        role.contains('analyst') ||
        role.contains('scientist')) {
      return _dataScientistTemplate;
    } else if (role.contains('sales') ||
        role.contains('marketing') ||
        role.contains('business development')) {
      return _marketingTemplate;
    } else if (role.contains('hr') ||
        role.contains('recruiter') ||
        role.contains('talent')) {
      return _hrTemplate;
    }

    return _genericTemplate;
  }

  static String _fillTemplate(
    JobTemplate template,
    String role,
    List<String> skills,
  ) {
    final skillsString = skills.isNotEmpty
        ? skills.join(', ')
        : 'relevant technologies';

    return '''
We are looking for a talented $role to join our team. 
Ideally, you should have experience in $skillsString.

Key Responsibilities:
${template.responsibilities.map((e) => '- $e').join('\n')}

Requirements:
${template.requirements.map((e) => '- $e').join('\n')}
''';
  }

  // Templates
  static final _mobileDevTemplate = JobTemplate(
    responsibilities: [
      'Design and build advanced applications for the mobile platform.',
      'Collaborate with cross-functional teams to define, design, and ship new features.',
      'Unit-test code for robustness, including edge cases, usability, and general reliability.',
      'Work on bug fixing and improving application performance.',
      'Continuously discover, evaluate, and implement new technologies to maximize development efficiency.',
    ],
    requirements: [
      'Proven software development experience and Android/iOS skills development.',
      'Experience with third-party libraries and APIs.',
      'Working knowledge of the general mobile landscape, architectures, trends, and emerging technologies.',
      'Solid understanding of the full mobile development life cycle.',
      'Experience with Git and Agile development methodologies.',
    ],
  );

  static final _backendDevTemplate = JobTemplate(
    responsibilities: [
      'Integration of user-facing elements developed by front-end developers with server-side logic.',
      'Building reusable code and libraries for future use.',
      'Optimization of the application for maximum speed and scalability.',
      'Implementation of security and data protection.',
      'Design and implementation of data storage solutions.',
    ],
    requirements: [
      'Basic understanding of front-end technologies and platforms, such as JavaScript, HTML5, and CSS3.',
      'Understanding accessibility and security compliance.',
      'User authentication and authorization between multiple systems, servers, and environments.',
      'Integration of multiple data sources and databases into one system.',
      'Proficient knowledge of a back-end programming language.',
    ],
  );

  static final _frontendDevTemplate = JobTemplate(
    responsibilities: [
      'Develop new user-facing features.',
      'Build reusable code and libraries for future use.',
      'Ensure the technical feasibility of UI/UX designs.',
      'Optimize application for maximum speed and scalability.',
      'Assure that all user input is validated before submitting to back-end.',
    ],
    requirements: [
      'Proficient understanding of web markup, including HTML5, CSS3.',
      'Basic understanding of server-side CSS pre-processing platforms, such as LESS and SASS.',
      'Proficient understanding of client-side scripting and JavaScript frameworks.',
      'Good understanding of advanced JavaScript libraries and frameworks.',
      'Proficient understanding of cross-browser compatibility issues and ways to work around them.',
    ],
  );

  static final _designerTemplate = JobTemplate(
    responsibilities: [
      'Gather and evaluate user requirements in collaboration with product managers and engineers.',
      'Illustrate design ideas using storyboards, process flows and sitemaps.',
      'Design graphic user interface elements, like menus, tabs and widgets.',
      'Build page navigation buttons and search fields.',
      'Develop UI mockups and prototypes that clearly illustrate how sites function and look like.',
    ],
    requirements: [
      'Proven work experience as a UI/UX Designer or similar role.',
      'Portfolio of design projects.',
      'Knowledge of wireframe tools (e.g. Wireframe.cc and InVision).',
      'Up-to-date knowledge of design software like Adobe Illustrator and Photoshop.',
      'Team spirit; strong communication skills to collaborate with various stakeholders.',
    ],
  );

  static final _productManagerTemplate = JobTemplate(
    responsibilities: [
      'Gain a deep understanding of customer experience, identify and fill product gaps and generate new ideas.',
      'Create buy-in for the product vision both internally and with key external partners.',
      'Translate product strategy into detailed requirements and prototypes.',
      'Scope and prioritize activities based on business and customer impact.',
      'Work closely with engineering teams to deliver with quick time-to-market and optimal resources.',
    ],
    requirements: [
      'Proven work experience in product management.',
      'Proven track record of managing all aspects of a successful product throughout its lifecycle.',
      'Proven ability to develop product and marketing strategies and effectively communicate recommendations to executive management.',
      'Solid technical background with understanding and/or hands-on experience in software development and web technologies.',
      'Strong problem solving skills and willingness to roll up one\'s sleeves to get the job.',
    ],
  );

  static final _dataScientistTemplate = JobTemplate(
    responsibilities: [
      'Identify valuable data sources and automate collection processes.',
      'Undertake preprocessing of structured and unstructured data.',
      'Analyze large amounts of information to discover trends and patterns.',
      'Build predictive models and machine-learning algorithms.',
      'Combine models through ensemble modeling.',
    ],
    requirements: [
      'Proven experience as a Data Scientist or Data Analyst.',
      'Experience in data mining.',
      'Understanding of machine-learning and operations research.',
      'Knowledge of R, SQL and Python; familiarity with Scala, Java or C++ is an asset.',
      'Analytical mind and business acumen.',
    ],
  );

  static final _marketingTemplate = JobTemplate(
    responsibilities: [
      'Develop strategies and tactics to get the word out about our company and drive qualified traffic to our front door.',
      'Deploy successful marketing campaigns and own their implementation from ideation to execution.',
      'Experiment with a variety of organic and paid acquisition channels.',
      'Produce valuable and engaging content for our website and blog.',
      'Measure and report on the performance of marketing campaigns.',
    ],
    requirements: [
      'Proven experience in identifying target audiences and in creatively devising and leading across channels marketing campaigns that engage, educate and motivate.',
      'Solid knowledge of website analytics tools (e.g., Google Analytics).',
      'Experience in setting up and optimizing Google Adwords campaigns.',
      'Numerically literate, comfortable working with numbers, making sense of metrics and processing figures with spreadsheets.',
      'A sense of aesthetics and a love for great copy and witty communication.',
    ],
  );

  static final _hrTemplate = JobTemplate(
    responsibilities: [
      'Develop and implement HR strategies and initiatives aligned with the overall business strategy.',
      'Bridge management and employee relations by addressing demands, grievances or other issues.',
      'Manage the recruitment and selection process.',
      'Support current and future business needs through the development, engagement, motivation and preservation of human capital.',
      'Nurture a positive working environment.',
    ],
    requirements: [
      'Proven working experience as HR Manager or other HR Executive.',
      'People oriented and results driven.',
      'Demonstrable experience with Human Resources metrics.',
      'Knowledge of HR systems and databases.',
      'Ability to architect strategy along with leadership skills.',
    ],
  );

  static final _genericTemplate = JobTemplate(
    responsibilities: [
      'Perform daily tasks efficiently and effectively.',
      'Collaborate with team members to achieve goals.',
      'Maintain high standards of quality in all work.',
      'Identify areas for improvement and suggest solutions.',
      'Adhere to company policies and procedures.',
    ],
    requirements: [
      'Relevant experience in the field.',
      'Strong communication and interpersonal skills.',
      'Ability to work independently and as part of a team.',
      'Detail-oriented with strong organizational skills.',
      'Willingness to learn and adapt to new challenges.',
    ],
  );
}

class JobTemplate {
  final List<String> responsibilities;
  final List<String> requirements;

  JobTemplate({required this.responsibilities, required this.requirements});
}
