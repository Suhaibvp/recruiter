import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final localAiServiceProvider = Provider<LocalAIService>((ref) {
  return LocalAIService();
});

class GeneratedJobContent {
  final String description;
  final List<String> responsibilities;
  final List<String> requirements;

  GeneratedJobContent({
    required this.description,
    required this.responsibilities,
    required this.requirements,
  });
}

class LocalAIService {
  static const _fallbackApiKey = 'AIzaSyA1cgxiFa9MVcqiJwaDqGuDmtziHzQj-Ec';
  final FirebaseFirestore _firestore;
  GenerativeModel? _model;
  String? _activeApiKey;
  Future<void>? _initFuture;

  LocalAIService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> _ensureInitialized() async {
    _initFuture ??= _init();
    return _initFuture;
  }

  Future<void> _init() async {
    final apiKey = await getApiKey();
    _activeApiKey = apiKey;
    _model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
  }

  Future<String> getApiKey() async {
    try {
      final doc = await _firestore
          .collection('configuration')
          .doc('ai_api_key')
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('key')) {
          final key = data['key'] as String?;
          if (key != null && key.trim().isNotEmpty) {
            return key.trim();
          }
        }
      }
    } catch (e) {
      print('Error fetching API key from Firestore, using fallback.');
    }
    return _fallbackApiKey;
  }

  String _sanitize(String text) {
    if (text.isEmpty) return text;
    var sanitized = text;
    if (_activeApiKey != null && _activeApiKey!.isNotEmpty) {
      sanitized = sanitized.replaceAll(_activeApiKey!, '[REDACTED]');
    }
    sanitized = sanitized.replaceAll(_fallbackApiKey, '[REDACTED]');
    return sanitized;
  }

  Future<GeneratedJobContent> generateJobContent(
    String role,
    List<String> skills,
  ) async {
    await _ensureInitialized();
    final model = _model!;
    final activeKey = _activeApiKey ?? '';

    if (activeKey == 'YOUR_API_KEY_HERE' || activeKey.isEmpty) {
      throw Exception(
        'Gemini API Key is missing. Please configure it.',
      );
    }

    final prompt =
        '''
    Generate a job description for the role of "$role".
    Key skills involved: ${skills.join(', ')}.

    Please provide the output in the following JSON format ONLY, without any markdown formatting:
    {
      "description": "A compelling 3-4 sentence job description.",
      "responsibilities": ["Responsibility 1", "Responsibility 2", "Responsibility 3", "Responsibility 4", "Responsibility 5", "Responsibility 6"],
      "requirements": ["Requirement 1", "Requirement 2", "Requirement 3", "Requirement 4", "Requirement 5", "Requirement 6"]
    }
    Make the tone professional and exciting.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final responseText = response.text;
      if (responseText == null) {
        throw Exception('Failed to generate content: No response from AI');
      }

      // Clean up potential markdown code blocks if the model includes them
      final cleanJson = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> data = jsonDecode(cleanJson);

      return GeneratedJobContent(
        description: data['description'] ?? '',
        responsibilities: List<String>.from(data['responsibilities'] ?? []),
        requirements: List<String>.from(data['requirements'] ?? []),
      );
    } catch (e) {
      final safeError = _sanitize(e.toString());
      print('Error generating job content: $safeError');
      throw Exception('Failed to generate job description: $safeError');
    }
  }
}
