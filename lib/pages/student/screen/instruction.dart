import 'package:flutter/material.dart';
import 'package:wipro_examination_portal/pages/student/screen/test_page_supabase.dart';

class InstructionPage extends StatefulWidget {
  final String registerNumber;
  
  const InstructionPage({Key? key, required this.registerNumber}) : super(key: key);

  @override
  _InstructionPageState createState() => _InstructionPageState();
}

class _InstructionPageState extends State<InstructionPage> {
  bool _hasReadInstructions = false;
  
  // Primary color
  static const Color primaryColor = Color(0xFF34419A);

  void _startExamination() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestPage(registerNumber: widget.registerNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width > 800;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 24.0,
              ),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  
                  // College Logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Image.asset(
                      'images/smvec_logo.png',
                      width: screenSize.width * 0.8,
                      height: screenSize.height * 0.15,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(); // Empty container if logo fails to load
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Examination Header
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Online Assesment - Wipro Clould Product And Platform Engineering",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Student Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_circle, color: primaryColor, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Register Number: ${widget.registerNumber}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Instructions Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: primaryColor, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Examination Guidelines & Instructions',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Pre-Exam Guidelines Section
                          _buildSectionTitle('Pre-Examination Guidelines'),
                          
                          _buildInstructionItem(
                            Icons.schedule,
                            'Entry Requirements',
                            'Join the examination portal 5 minutes before your scheduled batch time using your registered Registration Number only.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.badge,
                            'Identity Verification',
                            'Keep your College-ID card ready for verification. No other identity will be accepted.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.access_time_filled,
                            'Late Entry Policy',
                            'Late entry beyond 10 minutes after the commencement of the exam will NOT be permitted.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.library_books,
                            'Preparation Required',
                            'Ensure you have read and understood the UGC NEP 2020 framework and related materials before appearing.',
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Exam Format Section
                          _buildSectionTitle('Examination Format'),
                          
                          _buildInstructionItem(
                            Icons.quiz,
                            'Question Pattern',
                            'The examination consists of 50 Multiple Choice Questions (MCQs), each carrying 2 marks, for a total of 100 marks with NO negative marking.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.shuffle,
                            'Question Randomization',
                            'Questions will be auto-randomized from four sets prepared as per UGC NEP guidelines.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.timer,
                            'Time Duration',
                            'The exam duration is 60 minutes (1 hour). No extra time will be provided once the session ends.',
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // During Exam Section
                          _buildSectionTitle('During Examination'),
                          
                          _buildInstructionItem(
                            Icons.edit,
                            'Navigation',
                            'Use "Next" and "Previous" buttons to navigate between questions. You can change your answers before final submission.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.video_call,
                            'Online Proctoring',
                            'The exam will be proctored online. Ensure proper lighting and camera positioning for verification.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.warning_amber,
                            'Prohibited Activities',
                            'Any suspicious activity flagged by the proctoring system (tab switching, external help, disturbances) will be recorded and may lead to disqualification.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.phone_disabled,
                            'Device Guidelines',
                            'Keep your device charged and ensure stable internet connection. No external help is allowed.',
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Submission Guidelines Section
                          _buildSectionTitle('Submission Guidelines'),
                          
                          _buildInstructionItem(
                            Icons.task_alt,
                            'Manual Submission',
                            'Click "Submit Test" when you finish. Once submitted, answers cannot be modified.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.timer_off,
                            'Auto-Submit',
                            'The test will automatically submit when time expires.',
                          ),
                          
                          _buildInstructionItem(
                            Icons.refresh_outlined,
                            'Portal Restrictions',
                            'The exam portal should NOT be refreshed or closed until the submission is completed.',
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Critical Warning
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.priority_high, color: Colors.red, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CRITICAL WARNINGS:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '• Only ONE submission is allowed per student\n'
                                        '• Do NOT switch tabs or minimize the browser\n'
                                        '• After 2 warnings, your test will be auto-submitted for malpractice\n'
                                        '• Make sure you are ready before starting the examination',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // UGC NEP Info Box
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.school, color: Colors.blue.shade600, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'UGC NEP 2020 Framework:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'This examination is based on UGC National Education Policy 2020 guidelines. Ensure you are familiar with the framework before starting.',
                                        style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Acknowledgment Checkbox
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasReadInstructions,
                          onChanged: (value) {
                            setState(() {
                              _hasReadInstructions = value ?? false;
                            });
                          },
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'I have read and understood all the guidelines and instructions mentioned above. I agree to follow all examination rules and understand that any violation may lead to disqualification.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
      
                      
                      SizedBox(width: 16),
                      
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 54,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.play_arrow, size: 20),
                            label: Text(
                              'Start Examination',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _hasReadInstructions ? _startExamination : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasReadInstructions ? primaryColor : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _hasReadInstructions ? 4 : 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Footer
                  Text(
                    "© 2025 Wipro. All rights reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isDesktop ? 14 : 12,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}