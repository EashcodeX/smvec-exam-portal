import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:wipro_examination_portal/supabase_config.dart';
import 'package:wipro_examination_portal/services/email_service.dart';
import 'dart:typed_data';

class QuestionSetControllers {
  final TextEditingController nameController;
  final TextEditingController jsonController;

  QuestionSetControllers()
      : nameController = TextEditingController(),
        jsonController = TextEditingController();

  void dispose() {
    nameController.dispose();
    jsonController.dispose();
  }
}

class QsScreen extends StatefulWidget {
  final String adminId;

  const QsScreen({Key? key, required this.adminId}) : super(key: key);

  @override
  _QsScreenState createState() => _QsScreenState();
}

class _QsScreenState extends State<QsScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  List<QuestionSetControllers> _setControllers = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isBulkUploading = false;
  List<Map<String, dynamic>> _availableQuestionSets = [];
  String? _activeTestName;
  bool _isLoadingTests = false;

  @override
  void initState() {
    super.initState();
    // Start with one empty set field
    _addSet();
    // Load available tests for activation
    _loadAvailableTests();
  }

  void _addSet() {
    setState(() {
      _setControllers.add(QuestionSetControllers());
    });
  }

  void _removeSet(int index) {
    setState(() {
      _setControllers[index].dispose();
      _setControllers.removeAt(index);
    });
  }

  Future<void> _downloadResults() async {
    setState(() => _isDownloading = true);

    try {
      // Fetch all students data
      final studentsResponse = await SupabaseService.getAllStudents();

      // Fetch all test submissions
      final submissionsResponse = await SupabaseService.getAllSubmissions();

      // Process and format data
      List<Map<String, dynamic>> results = [];
      
      for (var submission in submissionsResponse) {
        // Find corresponding student
        final student = studentsResponse.firstWhere(
          (s) => s['register_number'] == submission['register_number'],
          orElse: () => {'name': 'Unknown', 'program': 'Unknown'},
        );

        String submittedAt = 'N/A';
        if (submission['submitted_at'] != null) {
          try {
            final dateTime = DateTime.parse(submission['submitted_at']);
            submittedAt = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            submittedAt = submission['submitted_at'].toString();
          }
        }

        results.add({
          'Register Number': submission['register_number'] ?? 'N/A',
          'Student Name': student['name'] ?? 'Unknown',
          'Program': student['program'] ?? 'Unknown',
          'Set Name': submission['set_name'] ?? 'N/A',
          'Total Score': submission['total_score'] ?? 0,
          'Max Score': submission['max_possible_score'] ?? 0,
          'Questions Attempted': submission['questions_attempted'] ?? 0,
          'Questions Correct': submission['questions_correct'] ?? 0,
          'Time Taken (min)': ((submission['time_taken_seconds'] ?? 0) / 60).round(),
          'Tab Switches': submission['tab_switch_count'] ?? 0,
          'Malpractice': submission['is_malpractice'] == true ? 'Yes' : 'No',
          'Auto Submitted': submission['auto_submitted'] == true ? 'Yes' : 'No',
          'Submitted At': submittedAt,
        });
      }

      // Convert to CSV
      if (results.isNotEmpty) {
        String csv = _convertToCSV(results);
        _downloadCSV(csv, 'test_results_${DateTime.now().millisecondsSinceEpoch}.csv');
        _showSnackBar("Results downloaded successfully!");
      } else {
        _showSnackBar("No results found to download.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error downloading results: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  String _convertToCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    
    // Get headers
    List<String> headers = data.first.keys.toList();
    String csv = headers.join(',') + '\n';
    
    // Add data rows
    for (var row in data) {
      List<String> values = headers.map((header) => 
        '"${row[header]?.toString().replaceAll('"', '""') ?? ''}"'
      ).toList();
      csv += values.join(',') + '\n';
    }
    
    return csv;
  }

  void _downloadCSV(String csvContent, String fileName) {
    if (kIsWeb) {
      // Web download
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _uploadQuestionSets() async {
    // Validate all sets first
    List<Map<String, dynamic>> parsedSets = [];
    
    for (int i = 0; i < _setControllers.length; i++) {
      final setName = _setControllers[i].nameController.text.trim();
      final jsonText = _setControllers[i].jsonController.text.trim();
      
      if (setName.isEmpty || jsonText.isEmpty) {
        _showSnackBar("Set ${i + 1}: Please fill in both set name and questions JSON.", isError: true);
        return;
      }
      
      try {
        final questions = jsonDecode(jsonText) as List<dynamic>;
        if (questions.isEmpty) {
          _showSnackBar("Set ${i + 1}: Questions list cannot be empty.", isError: true);
          return;
        }
        
        parsedSets.add({
          'setName': setName,
          'questions': questions,
        });
      } catch (e) {
        _showSnackBar("Set ${i + 1}: Invalid JSON format. ${e.toString()}", isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Get admin ID
      final adminResponse = await _supabase
          .from(SupabaseTables.admins)
          .select('id')
          .eq('name', widget.adminId)
          .single();

      final adminId = adminResponse['id'];

      // Upload each question set
      for (var setData in parsedSets) {
        String setName = setData['setName'];
        List<dynamic> questions = setData['questions'];

        // Create question set
        final questionSetResponse = await _supabase
            .from(SupabaseTables.questionSets)
            .insert({
              'set_name': setName,
              'admin_id': adminId,
            })
            .select()
            .single();

        final questionSetId = questionSetResponse['id'];

        // Add each question
        for (var questionData in questions) {
          await _supabase
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
      }

      _showSnackBar("${parsedSets.length} set(s) uploaded successfully!");

      setState(() {
        for (var controller in _setControllers) {
          controller.dispose();
        }
        _setControllers = [];
        _addSet();
      });
    } catch (e) {
      _showSnackBar("Error during upload: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }



  // Bulk upload from CSV file
  Future<void> _bulkUploadFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isBulkUploading = true);

        String csvContent = String.fromCharCodes(result.files.single.bytes!);
        await _processBulkUpload(csvContent);
      }
    } catch (e) {
      _showSnackBar("Error picking file: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isBulkUploading = false);
    }
  }

  // Process bulk upload from CSV content
  Future<void> _processBulkUpload(String csvContent) async {
    try {
      List<String> lines = csvContent.split('\n');
      if (lines.isEmpty) {
        _showSnackBar("CSV file is empty", isError: true);
        return;
      }

      // Parse CSV header
      List<String> headers = lines[0].split(',').map((h) => h.trim().replaceAll('"', '')).toList();

      // Validate required headers
      List<String> requiredHeaders = ['set_name', 'question_number', 'question', 'option_a', 'option_b', 'option_c', 'option_d', 'correct_answer'];
      for (String required in requiredHeaders) {
        if (!headers.contains(required)) {
          _showSnackBar("Missing required column: $required", isError: true);
          return;
        }
      }

      // Group questions by set_name
      Map<String, List<Map<String, dynamic>>> questionSets = {};

      for (int i = 1; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;

        List<String> values = _parseCSVLine(line);
        if (values.length != headers.length) continue;

        Map<String, String> row = {};
        for (int j = 0; j < headers.length; j++) {
          row[headers[j]] = values[j];
        }

        String setName = row['set_name'] ?? '';
        if (setName.isEmpty) continue;

        if (!questionSets.containsKey(setName)) {
          questionSets[setName] = [];
        }

        questionSets[setName]!.add({
          'question_number': int.tryParse(row['question_number'] ?? '0') ?? 0,
          'qs': row['question'] ?? '',
          'option': [
            row['option_a'] ?? '',
            row['option_b'] ?? '',
            row['option_c'] ?? '',
            row['option_d'] ?? '',
          ],
          'correct_ans': row['correct_answer'] ?? '',
          'type': row['type'] ?? 'multiple_choice',
        });
      }

      if (questionSets.isEmpty) {
        _showSnackBar("No valid questions found in CSV", isError: true);
        return;
      }

      // Upload each question set
      await _uploadBulkQuestionSets(questionSets);

    } catch (e) {
      _showSnackBar("Error processing CSV: ${e.toString()}", isError: true);
    }
  }

  // Parse CSV line handling quoted values
  List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    result.add(current.trim());
    return result;
  }

  // Upload bulk question sets
  Future<void> _uploadBulkQuestionSets(Map<String, List<Map<String, dynamic>>> questionSets) async {
    try {
      // Get admin ID
      final adminResponse = await _supabase
          .from(SupabaseTables.admins)
          .select('id')
          .eq('name', widget.adminId)
          .single();

      final adminId = adminResponse['id'];

      int totalSets = 0;
      int totalQuestions = 0;

      // Upload each question set
      for (String setName in questionSets.keys) {
        List<Map<String, dynamic>> questions = questionSets[setName]!;

        // Create question set
        final questionSetResponse = await _supabase
            .from(SupabaseTables.questionSets)
            .insert({
              'set_name': setName,
              'admin_id': adminId,
            })
            .select()
            .single();

        final questionSetId = questionSetResponse['id'];

        // Add each question
        for (var questionData in questions) {
          await _supabase
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
                'question_type': questionData['type'],
              });
        }

        totalSets++;
        totalQuestions += questions.length;
      }

      _showSnackBar("Successfully uploaded $totalSets set(s) with $totalQuestions questions!");

      // Send email notification
      await _sendBulkUploadEmail(questionSets.keys.toList(), totalQuestions);

    } catch (e) {
      _showSnackBar("Error uploading bulk questions: ${e.toString()}", isError: true);
    }
  }

  // Generate sample CSV template
  void _downloadSampleCSV() {
    String sampleCSV = '''set_name,question_number,question,option_a,option_b,option_c,option_d,correct_answer,type
"Sample Set 1",1,"What is the capital of India?","New Delhi","Mumbai","Kolkata","Chennai","New Delhi","multiple_choice"
"Sample Set 1",2,"Flutter is developed by which company?","Google","Microsoft","Apple","Meta","Google","multiple_choice"
"Sample Set 2",1,"What is 2 + 2?","3","4","5","6","4","multiple_choice"
"Sample Set 2",2,"Which programming language is used for Flutter?","Java","Dart","Python","JavaScript","Dart","multiple_choice"''';

    if (kIsWeb) {
      final bytes = utf8.encode(sampleCSV);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'sample_questions_template.csv';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }

    _showSnackBar("Sample CSV template downloaded!");
  }

  // Load available question sets and current active test
  Future<void> _loadAvailableTests() async {
    setState(() => _isLoadingTests = true);

    try {
      // Get all question sets with question counts
      final questionSetsResponse = await _supabase
          .from(SupabaseTables.questionSets)
          .select('*, questions(count)')
          .order('created_at', ascending: false);

      // Get current active test
      final activeTestResponse = await _supabase
          .from(SupabaseTables.activeTest)
          .select('*')
          .maybeSingle();

      setState(() {
        _availableQuestionSets = List<Map<String, dynamic>>.from(questionSetsResponse);
        _activeTestName = activeTestResponse?['active_set_name'];
      });
    } catch (e) {
      _showSnackBar('Error loading tests: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoadingTests = false);
    }
  }

  // Activate a specific test set
  Future<void> _activateTestSet(String setName, String questionSetId) async {
    setState(() => _isLoadingTests = true);

    try {
      // Get admin ID
      final adminResponse = await _supabase
          .from(SupabaseTables.admins)
          .select('id')
          .eq('name', widget.adminId)
          .single();

      final adminId = adminResponse['id'];

      // Clear existing active test
      await _supabase
          .from(SupabaseTables.activeTest)
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000');

      // Set new active test
      await _supabase
          .from(SupabaseTables.activeTest)
          .insert({
            'active_set_name': setName,
            'question_set_id': questionSetId,
            'activated_by': adminId,
          });

      _showSnackBar("'$setName' is now the active test!");

      // Send email notification
      await _sendTestActivationEmail(setName, questionSetId);

      await _loadAvailableTests(); // Refresh the list
    } catch (e) {
      _showSnackBar("Failed to activate test: $e", isError: true);
    } finally {
      setState(() => _isLoadingTests = false);
    }
  }

  // Deactivate current test
  Future<void> _deactivateCurrentTest() async {
    setState(() => _isLoadingTests = true);

    try {
      await _supabase
          .from(SupabaseTables.activeTest)
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000');

      _showSnackBar("Test deactivated successfully!");
      await _loadAvailableTests(); // Refresh the list
    } catch (e) {
      _showSnackBar("Failed to deactivate test: $e", isError: true);
    } finally {
      setState(() => _isLoadingTests = false);
    }
  }

  // Delete a question set
  Future<void> _deleteQuestionSet(String questionSetId, String setName) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Question Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete the question set:'),
              SizedBox(height: 8),
              Text(
                '"$setName"',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 16),
              Text(
                '⚠️ This action will permanently delete:',
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• All questions in this set'),
              Text('• All student results for this set'),
              Text('• The question set itself'),
              SizedBox(height: 16),
              Text(
                'This action cannot be undone!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoadingTests = true);

    try {
      final result = await SupabaseService.deleteQuestionSet(questionSetId);

      if (result['success']) {
        _showSnackBar("Question set '$setName' deleted successfully!");
        await _loadAvailableTests(); // Refresh the list
      } else {
        _showSnackBar("Failed to delete question set: ${result['error']}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Failed to delete question set: $e", isError: true);
    } finally {
      setState(() => _isLoadingTests = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Send test activation email notification
  Future<void> _sendTestActivationEmail(String setName, String questionSetId) async {
    try {
      // Get question count for the set
      final questionsResponse = await _supabase
          .from(SupabaseTables.questions)
          .select('id')
          .eq('question_set_id', questionSetId);

      final questionCount = questionsResponse.length;

      await EmailService.sendTestActivationEmail(
        testName: setName,
        questionCount: questionCount,
        activatedBy: widget.adminId,
      );
    } catch (e) {
      print('Error sending test activation email: $e');
      // Don't show error to user as email is not critical
    }
  }

  // Send bulk upload notification email
  Future<void> _sendBulkUploadEmail(List<String> setNames, int totalQuestions) async {
    try {
      await EmailService.sendBulkUploadNotificationEmail(
        uploadedBy: widget.adminId,
        questionSetsCount: setNames.length,
        totalQuestions: totalQuestions,
        setNames: setNames,
      );
    } catch (e) {
      print('Error sending bulk upload email: $e');
      // Don't show error to user as email is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question Management - ${widget.adminId}'),
        backgroundColor: Color(0xFF34419A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDownloading ? Icons.hourglass_empty : Icons.download),
            onPressed: _isDownloading ? null : _downloadResults,
            tooltip: 'Download Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Upload Section
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _setControllers.length,
              itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Question Set ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_setControllers.length > 1)
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeSet(index),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _setControllers[index].nameController,
                            decoration: InputDecoration(
                              labelText: 'Set Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _setControllers[index].jsonController,
                            decoration: InputDecoration(
                              labelText: 'Questions JSON',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            SizedBox(height: 24),

            // Test Activation Section
            Container(
              margin: EdgeInsets.symmetric(vertical: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline, color: Colors.green[800]),
                      SizedBox(width: 8),
                      Text(
                        '🎯 Test Activation Control',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (_activeTestName != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Currently Active: $_activeTestName',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoadingTests ? null : _deactivateCurrentTest,
                            icon: _isLoadingTests
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(Icons.stop, size: 16),
                            label: Text('Deactivate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700], size: 20),
                          SizedBox(width: 8),
                          Text(
                            'No test is currently active. Students cannot take tests.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                  Text(
                    'Available Question Sets:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  if (_isLoadingTests)
                    Center(child: CircularProgressIndicator())
                  else if (_availableQuestionSets.isEmpty)
                    Text(
                      'No question sets available. Create some question sets first.',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Column(
                      children: _availableQuestionSets.map((questionSet) {
                        final setName = questionSet['set_name'];
                        final questionCount = questionSet['questions']?.length ?? 0;
                        final isActive = setName == _activeTestName;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green[100] : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive ? Colors.green[300]! : Colors.grey[300]!,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? Colors.green : Colors.grey[400],
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      setName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? Colors.green[800] : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '$questionCount questions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isActive)
                                    ElevatedButton.icon(
                                      onPressed: _isLoadingTests
                                          ? null
                                          : () => _activateTestSet(setName, questionSet['id']),
                                      icon: Icon(Icons.play_arrow, size: 16),
                                      label: Text('Activate'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _isLoadingTests
                                        ? null
                                        : () => _deleteQuestionSet(questionSet['id'], setName),
                                    icon: Icon(Icons.delete, size: 18),
                                    color: Colors.red[600],
                                    tooltip: 'Delete Question Set',
                                    padding: EdgeInsets.all(8),
                                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Bulk Upload Section
            Container(
              margin: EdgeInsets.symmetric(vertical: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📁 Bulk Upload Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Upload multiple question sets from a CSV file. Download the sample template first to see the required format.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _downloadSampleCSV,
                        icon: Icon(Icons.file_download),
                        label: Text('Download Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isBulkUploading ? null : _bulkUploadFromFile,
                        icon: _isBulkUploading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.upload_file),
                        label: Text(_isBulkUploading ? 'Uploading...' : 'Upload CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _addSet,
                  icon: Icon(Icons.add),
                  label: Text('Add Set'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadQuestionSets,
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.upload),
                  label: Text(_isLoading ? 'Uploading...' : 'Upload Sets'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF34419A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadResults,
                  icon: _isDownloading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.download),
                  label: Text(_isDownloading ? 'Downloading...' : 'Download Results'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _setControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
