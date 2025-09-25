import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Your Supabase project credentials
  static const String supabaseUrl = 'https://yzurlvfjzgxreuvilzbj.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6dXJsdmZqemd4cmV1dmlsemJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2OTczNTksImV4cCI6MjA3NDI3MzM1OX0.Wj3IMc-ngGypF-fTpC9GTB_4CdAm28dAWYEsD51SyH4';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

// Database table names
class SupabaseTables {
  static const String admins = 'admins';
  static const String students = 'students';
  static const String questionSets = 'question_sets';
  static const String questions = 'questions';
  static const String activeTest = 'active_test';
  static const String testSubmissions = 'test_submissions';
}

// Supabase service class that replicates Firebase functionality
class SupabaseService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Admin authentication
  static Future<Map<String, dynamic>?> authenticateAdmin(String name, String password) async {
    try {
      final response = await _client
          .from(SupabaseTables.admins)
          .select('*')
          .eq('name', name)
          .eq('password', password)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Admin auth error: $e');
      return null;
    }
  }

  // Student authentication
  static Future<Map<String, dynamic>?> authenticateStudent(String registerNumber, String password) async {
    try {
      final response = await _client
          .from(SupabaseTables.students)
          .select('*')
          .eq('register_number', registerNumber)
          .eq('password', password)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Student auth error: $e');
      return null;
    }
  }

  // Get student by register number (for already authenticated students)
  static Future<Map<String, dynamic>?> getStudentByRegisterNumber(String registerNumber) async {
    try {
      final response = await _client
          .from(SupabaseTables.students)
          .select('*')
          .eq('register_number', registerNumber)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get student error: $e');
      return null;
    }
  }

  // Get active test
  static Future<Map<String, dynamic>?> getActiveTest() async {
    try {
      final response = await _client
          .from(SupabaseTables.activeTest)
          .select('*, question_sets(*)')
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get active test error: $e');
      return null;
    }
  }

  // Get questions for a test set
  static Future<List<Map<String, dynamic>>> getQuestions(String questionSetId) async {
    try {
      final response = await _client
          .from(SupabaseTables.questions)
          .select('*')
          .eq('question_set_id', questionSetId)
          .order('question_number');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get questions error: $e');
      return [];
    }
  }

  // Check if student has already submitted
  static Future<bool> hasStudentSubmitted(String registerNumber, String questionSetId) async {
    try {
      final response = await _client
          .from(SupabaseTables.testSubmissions)
          .select('id')
          .eq('register_number', registerNumber)
          .eq('question_set_id', questionSetId);
      return response.isNotEmpty;
    } catch (e) {
      print('Check submission error: $e');
      return false;
    }
  }

  // Submit test results
  static Future<bool> submitTestResults(Map<String, dynamic> submissionData) async {
    try {
      await _client
          .from(SupabaseTables.testSubmissions)
          .insert(submissionData);
      return true;
    } catch (e) {
      print('Submit test error: $e');
      return false;
    }
  }

  // Create question set (Admin functionality)
  static Future<String?> createQuestionSet(String setName, String adminId) async {
    try {
      final response = await _client
          .from(SupabaseTables.questionSets)
          .insert({
            'set_name': setName,
            'admin_id': adminId,
          })
          .select()
          .single();
      return response['id'];
    } catch (e) {
      print('Create question set error: $e');
      return null;
    }
  }

  // Add questions to a set
  static Future<bool> addQuestionsToSet(String questionSetId, List<Map<String, dynamic>> questions) async {
    try {
      for (var questionData in questions) {
        await _client
            .from(SupabaseTables.questions)
            .insert({
              'question_set_id': questionSetId,
              'question_number': questionData['question_number'],
              'question_text': questionData['qs'],
              'option_a': questionData['option'][0],
              'option_b': questionData['option'][1],
              'option_c': questionData['option'][2],
              'option_d': questionData['option'][3],
              'correct_answer': questionData['correct_ans'],
              'question_type': questionData['type'] ?? 'multiple_choice',
            });
      }
      return true;
    } catch (e) {
      print('Add questions error: $e');
      return false;
    }
  }

  // Activate a test set
  static Future<bool> activateTestSet(String setName, String adminId) async {
    try {
      // Get question set ID
      final questionSetResponse = await _client
          .from(SupabaseTables.questionSets)
          .select('id')
          .eq('set_name', setName)
          .single();

      final questionSetId = questionSetResponse['id'];

      // Clear existing active test
      await _client
          .from(SupabaseTables.activeTest)
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000');

      // Set new active test
      await _client
          .from(SupabaseTables.activeTest)
          .insert({
            'active_set_name': setName,
            'question_set_id': questionSetId,
            'activated_by': adminId,
          });

      return true;
    } catch (e) {
      print('Activate test set error: $e');
      return false;
    }
  }

  // Get all test submissions (Admin functionality)
  static Future<List<Map<String, dynamic>>> getAllSubmissions() async {
    try {
      final response = await _client
          .from(SupabaseTables.testSubmissions)
          .select('*')
          .order('submitted_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get submissions error: $e');
      return [];
    }
  }

  // Get all students (Admin functionality)
  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await _client
          .from(SupabaseTables.students)
          .select('*')
          .order('register_number');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get students error: $e');
      return [];
    }
  }

  // Get all question sets (Admin functionality)
  static Future<List<Map<String, dynamic>>> getAllQuestionSets() async {
    try {
      final response = await _client
          .from(SupabaseTables.questionSets)
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get question sets error: $e');
      return [];
    }
  }

  // Delete a question set and all its questions
  static Future<Map<String, dynamic>> deleteQuestionSet(String questionSetId) async {
    try {
      // First, check if this question set is currently active
      final activeTestResponse = await _client
          .from(SupabaseTables.activeTest)
          .select('question_set_id')
          .eq('question_set_id', questionSetId)
          .maybeSingle();

      if (activeTestResponse != null) {
        return {
          'success': false,
          'error': 'Cannot delete an active question set. Please deactivate it first.'
        };
      }

      // Delete all questions in this set first (due to foreign key constraints)
      await _client
          .from(SupabaseTables.questions)
          .delete()
          .eq('question_set_id', questionSetId);

      // Delete any student results for this question set
      await _client
          .from(SupabaseTables.testSubmissions)
          .delete()
          .eq('question_set_id', questionSetId);

      // Finally, delete the question set itself
      await _client
          .from(SupabaseTables.questionSets)
          .delete()
          .eq('id', questionSetId);

      return {'success': true, 'message': 'Question set deleted successfully'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
