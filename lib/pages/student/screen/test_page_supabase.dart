import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:wipro_examination_portal/supabase_config.dart';
import 'package:wipro_examination_portal/services/email_service.dart';

class TestPage extends StatefulWidget {
  final String registerNumber;

  const TestPage({Key? key, required this.registerNumber}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _userAnswers = {};
  int _currentQuestionIndex = 0;
  int _timeLeft = 3600; // 60 minutes in seconds
  Timer? _timer;
  bool _isSubmitting = false;
  bool _timerExpired = false;
  int _tabSwitchCount = 0;
  String _setName = '';
  String _questionSetId = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
    _setupVisibilityListener();
  }

  void _setupVisibilityListener() {
    // Track tab switches for malpractice detection
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == AppLifecycleState.paused.toString()) {
        setState(() {
          _tabSwitchCount++;
        });
      }
      return null;
    });
  }

  Future<void> _loadQuestions() async {
    try {
      // Get student info (already authenticated, just fetch data)
      final studentResponse = await SupabaseService.getStudentByRegisterNumber(widget.registerNumber);
      if (studentResponse == null) {
        _showErrorDialog('Student not found. Please contact administrator.');
        return;
      }

      // Get active test
      final activeTestResponse = await SupabaseService.getActiveTest();
      if (activeTestResponse == null) {
        _showErrorDialog('No active test found');
        return;
      }

      _setName = activeTestResponse['active_set_name'];
      _questionSetId = activeTestResponse['question_set_id'];

      // Get questions for the active test
      final questionsResponse = await SupabaseService.getQuestions(_questionSetId);

      setState(() {
        _questions = questionsResponse.map<Map<String, dynamic>>((q) => {
          'question_number': q['question_number'],
          'qs': q['question_text'],
          'option': [
            q['option_a'],
            q['option_b'],
            q['option_c'],
            q['option_d'],
          ],
          'correct_ans': q['correct_answer'],
          'type': q['question_type'] ?? 'multiple_choice',
        }).toList();
      });

      // Shuffle options for each question
      for (var question in _questions) {
        _shuffleOptions(question);
      }

      // Check if student has already submitted
      await _checkExistingSubmission();

    } catch (e) {
      _showErrorDialog('Error loading questions: ${e.toString()}');
    }
  }

  void _shuffleOptions(Map<String, dynamic> question) {
    List<String> options = List<String>.from(question['option']);
    String correctAnswer = question['correct_ans'];
    
    options.shuffle(Random());
    question['option'] = options;
    
    // Update correct answer index
    int correctIndex = options.indexOf(correctAnswer);
    question['correct_index'] = correctIndex;
  }

  Future<void> _checkExistingSubmission() async {
    try {
      final hasSubmitted = await SupabaseService.hasStudentSubmitted(widget.registerNumber, _questionSetId);

      if (hasSubmitted) {
        _showErrorDialog('You have already submitted this test.');
        return;
      }
    } catch (e) {
      print('Error checking existing submission: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timerExpired = true;
          _submitTest(autoSubmit: true);
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(String answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _goToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  int _calculateScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers.containsKey(i)) {
        String userAnswer = _userAnswers[i]!;
        String correctAnswer = _questions[i]['correct_ans'];
        if (userAnswer == correctAnswer) {
          score++;
        }
      }
    }
    return score;
  }

  Future<void> _submitTest({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    try {
      int score = _calculateScore();
      bool isMalpractice = _tabSwitchCount > 3; // Threshold for malpractice

      // Prepare answers data
      Map<String, dynamic> answersData = {};
      for (int i = 0; i < _questions.length; i++) {
        answersData['question_${i + 1}'] = {
          'question': _questions[i]['qs'],
          'user_answer': _userAnswers[i] ?? 'Not Answered',
          'correct_answer': _questions[i]['correct_ans'],
          'is_correct': _userAnswers.containsKey(i) && 
                       _userAnswers[i] == _questions[i]['correct_ans'],
        };
      }

      // Submit to Supabase
      final submissionData = {
        'register_number': widget.registerNumber,
        'set_name': _setName,
        'question_set_id': _questionSetId,
        'total_score': score,
        'max_possible_score': _questions.length,
        'total_questions': _questions.length,
        'questions_attempted': _userAnswers.length,
        'questions_correct': score,
        'time_taken_seconds': 3600 - _timeLeft,
        'tab_switch_count': _tabSwitchCount,
        'is_malpractice': isMalpractice,
        'auto_submitted': autoSubmit || _timerExpired,
        'answers': answersData,
      };

      final success = await SupabaseService.submitTestResults(submissionData);
      if (!success) {
        throw Exception('Failed to submit test results');
      }

      // Send email notifications
      await _sendEmailNotifications(score, isMalpractice);

      // Show professional thank you message instead of results
      _showThankYouDialog();

    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('Error submitting test: ${e.toString()}');
    }
  }

  Future<void> _sendEmailNotifications(int score, bool isMalpractice) async {
    try {
      // Get student information
      final student = await SupabaseService.getStudentByRegisterNumber(widget.registerNumber);
      if (student == null) return;

      final studentName = student['name'] ?? 'Student';
      final studentEmail = student['gmail'] ?? '';

      // Format time taken
      final timeTakenMinutes = ((3600 - _timeLeft) / 60).round();
      final timeTaken = '$timeTakenMinutes minutes';

      // Send email to student (if email is available)
      if (studentEmail.isNotEmpty && studentEmail.contains('@')) {
        await EmailService.sendTestCompletionEmail(
          studentEmail: studentEmail,
          studentName: studentName,
          testName: _setName,
          score: score,
          totalQuestions: _questions.length,
          timeTaken: timeTaken,
          isMalpractice: isMalpractice,
        );
      }

      // Send admin notification
      await EmailService.sendAdminNotificationEmail(
        studentName: studentName,
        registerNumber: widget.registerNumber,
        testName: _setName,
        score: score,
        totalQuestions: _questions.length,
        isMalpractice: isMalpractice,
        timeTaken: timeTaken,
      );
    } catch (e) {
      print('Error sending email notifications: $e');
      // Don't show error to user as email is not critical for test submission
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF34419A), Color(0xFF667eea)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Test Submitted Successfully',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),

              // Thank you message
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 Thank You for Participating!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your examination has been submitted successfully and is now under review.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Results information
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.blue.shade600, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Results Notification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Your detailed results will be sent to your registered email address',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade600),
                    ),
                    Text(
                      '• Results will be available within 24 hours',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade600),
                    ),
                    Text(
                      '• Official results will be communicated by the examination committee',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Support information
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: Colors.grey.shade600, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'For any queries regarding your examination, please contact:',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Email: support@wipro.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Wipro branding
              Center(
                child: Column(
                  children: [
                    Text(
                      'Wipro Examination Portal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34419A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '© 2025 Wipro Limited. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF34419A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Return to Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading Test...'),
          backgroundColor: Color(0xFF34419A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Test - ${widget.registerNumber}'),
        backgroundColor: Color(0xFF34419A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                _formatTime(_timeLeft),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft < 300 ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Question navigation panel
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      bool isAnswered = _userAnswers.containsKey(index);
                      bool isCurrent = index == _currentQuestionIndex;
                      
                      return GestureDetector(
                        onTap: () => _goToQuestion(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Color(0xFF34419A)
                                : isAnswered
                                    ? Colors.green
                                    : Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent || isAnswered
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Answered: ${_userAnswers.length}/${_questions.length}'),
                      SizedBox(height: 8),
                      Text('Tab Switches: $_tabSwitchCount'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitTest(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Submit Test'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main question area
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question header
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Question text
                  Text(
                    currentQuestion['qs'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24),
                  // Options
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestion['option'].length,
                      itemBuilder: (context, index) {
                        String option = currentQuestion['option'][index];
                        bool isSelected = _userAnswers[_currentQuestionIndex] == option;
                        
                        return GestureDetector(
                          onTap: () => _selectAnswer(option),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFF34419A).withOpacity(0.1) : Colors.white,
                              border: Border.all(
                                color: isSelected ? Color(0xFF34419A) : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Color(0xFF34419A) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Color(0xFF34419A) : Colors.grey,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected ? Color(0xFF34419A) : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                        child: Text('Previous'),
                      ),
                      ElevatedButton(
                        onPressed: _currentQuestionIndex < _questions.length - 1 ? _nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34419A),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
