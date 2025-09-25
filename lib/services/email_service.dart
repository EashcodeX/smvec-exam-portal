import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // SMTP Configuration
  static const String _senderEmail = "rsaravanan26@gmail.com";
  static const String _senderPassword = "emzl vzrl cskk dxes";
  static const String _smtpServer = "smtp.gmail.com";
  static const int _smtpPort = 587;
  static const String _senderName = "Wipro Examination Portal";

  // Get SMTP server configuration
  static SmtpServer get _smtpConfig => gmail(_senderEmail, _senderPassword);

  // Send email method
  static Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String htmlBody,
    String? plainTextBody,
    List<String>? ccEmails,
    List<String>? bccEmails,
  }) async {
    try {
      // Skip email sending in web debug mode to avoid CORS issues
      if (kIsWeb && kDebugMode) {
        print('📧 EMAIL SIMULATION (Web Debug Mode)');
        print('To: $recipientEmail');
        print('Subject: $subject');
        print('Body: $plainTextBody');
        print('HTML: $htmlBody');
        return true;
      }

      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..text = plainTextBody ?? _stripHtml(htmlBody)
        ..html = htmlBody;

      // Add CC recipients if provided
      if (ccEmails != null && ccEmails.isNotEmpty) {
        for (String ccEmail in ccEmails) {
          message.recipients.add(ccEmail);
        }
      }

      // Add BCC recipients if provided
      if (bccEmails != null && bccEmails.isNotEmpty) {
        for (String bccEmail in bccEmails) {
          message.recipients.add(bccEmail);
        }
      }

      final sendReport = await send(message, _smtpConfig);
      print('📧 Email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('❌ Email sending failed: $e');
      return false;
    }
  }

  // Strip HTML tags for plain text version
  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // Send test completion notification to student
  static Future<bool> sendTestCompletionEmail({
    required String studentEmail,
    required String studentName,
    required String testName,
    required int score,
    required int totalQuestions,
    required String timeTaken,
    required bool isMalpractice,
  }) async {
    final subject = 'Test Completion - $testName';
    
    final htmlBody = '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .score-card { background: #f8f9fa; border-left: 4px solid #007bff; padding: 15px; margin: 20px 0; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
            .footer { background: #f8f9fa; padding: 15px; text-align: center; font-size: 12px; color: #666; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🎯 Wipro Examination Portal</h1>
            <h2>Test Completion Notification</h2>
        </div>
        
        <div class="content">
            <p>Dear <strong>$studentName</strong>,</p>
            
            <p>You have successfully completed the <strong>$testName</strong> examination.</p>
            
            <div class="score-card">
                <h3>📊 Your Results:</h3>
                <ul>
                    <li><strong>Score:</strong> $score out of $totalQuestions</li>
                    <li><strong>Percentage:</strong> ${((score / totalQuestions) * 100).toStringAsFixed(1)}%</li>
                    <li><strong>Time Taken:</strong> $timeTaken</li>
                    <li><strong>Test:</strong> $testName</li>
                </ul>
            </div>
            
            ${isMalpractice ? '''
            <div class="warning">
                <h3>⚠️ Important Notice:</h3>
                <p>Our system detected unusual activity during your test (multiple tab switches). This has been flagged for review by the examination committee.</p>
            </div>
            ''' : ''}
            
            <p>Your responses have been recorded and will be reviewed by the examination committee. Official results will be communicated separately.</p>
            
            <p>Thank you for participating in the Wipro assessment.</p>
            
            <p>Best regards,<br>
            <strong>Wipro Examination Team</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 Wipro Limited. All rights reserved.</p>
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </body>
    </html>
    ''';

    return await sendEmail(
      recipientEmail: studentEmail,
      subject: subject,
      htmlBody: htmlBody,
    );
  }

  // Send admin notification for new test submission
  static Future<bool> sendAdminNotificationEmail({
    required String studentName,
    required String registerNumber,
    required String testName,
    required int score,
    required int totalQuestions,
    required bool isMalpractice,
    required String timeTaken,
  }) async {
    const adminEmail = "rsaravanan26@gmail.com"; // Admin email
    final subject = 'New Test Submission - $studentName';
    
    final htmlBody = '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background: #34419A; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .info-card { background: #f8f9fa; border: 1px solid #dee2e6; padding: 15px; margin: 15px 0; border-radius: 5px; }
            .alert { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; margin: 15px 0; border-radius: 5px; }
            .footer { background: #f8f9fa; padding: 15px; text-align: center; font-size: 12px; color: #666; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔔 Wipro Examination Portal</h1>
            <h2>Admin Notification - New Submission</h2>
        </div>
        
        <div class="content">
            <p>Dear Administrator,</p>
            
            <p>A new test submission has been received:</p>
            
            <div class="info-card">
                <h3>📋 Submission Details:</h3>
                <ul>
                    <li><strong>Student:</strong> $studentName</li>
                    <li><strong>Register Number:</strong> $registerNumber</li>
                    <li><strong>Test:</strong> $testName</li>
                    <li><strong>Score:</strong> $score/$totalQuestions (${((score / totalQuestions) * 100).toStringAsFixed(1)}%)</li>
                    <li><strong>Time Taken:</strong> $timeTaken</li>
                    <li><strong>Submission Time:</strong> ${DateTime.now().toString()}</li>
                </ul>
            </div>
            
            ${isMalpractice ? '''
            <div class="alert">
                <h3>⚠️ Malpractice Alert:</h3>
                <p>This submission has been flagged for potential malpractice due to excessive tab switching during the examination. Please review the submission carefully.</p>
            </div>
            ''' : ''}
            
            <p>Please log into the admin panel to review the detailed submission and take appropriate action.</p>
            
            <p>Best regards,<br>
            <strong>Wipro Examination System</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 Wipro Limited. All rights reserved.</p>
            <p>This is an automated notification from the Wipro Examination Portal.</p>
        </div>
    </body>
    </html>
    ''';

    return await sendEmail(
      recipientEmail: adminEmail,
      subject: subject,
      htmlBody: htmlBody,
    );
  }

  // Send test activation notification to admin
  static Future<bool> sendTestActivationEmail({
    required String testName,
    required int questionCount,
    required String activatedBy,
  }) async {
    const adminEmail = "rsaravanan26@gmail.com";
    final subject = 'Test Activated - $testName';
    
    final htmlBody = '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background: #28a745; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .info-card { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; margin: 15px 0; border-radius: 5px; }
            .footer { background: #f8f9fa; padding: 15px; text-align: center; font-size: 12px; color: #666; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>✅ Wipro Examination Portal</h1>
            <h2>Test Activation Notification</h2>
        </div>
        
        <div class="content">
            <p>Dear Administrator,</p>
            
            <div class="info-card">
                <h3>🎯 Test Activation Details:</h3>
                <ul>
                    <li><strong>Test Name:</strong> $testName</li>
                    <li><strong>Question Count:</strong> $questionCount questions</li>
                    <li><strong>Activated By:</strong> $activatedBy</li>
                    <li><strong>Activation Time:</strong> ${DateTime.now().toString()}</li>
                </ul>
            </div>
            
            <p>The test is now <strong>ACTIVE</strong> and available for students to take.</p>
            
            <p>Students can now access this test through the examination portal.</p>
            
            <p>Best regards,<br>
            <strong>Wipro Examination System</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 Wipro Limited. All rights reserved.</p>
        </div>
    </body>
    </html>
    ''';

    return await sendEmail(
      recipientEmail: adminEmail,
      subject: subject,
      htmlBody: htmlBody,
    );
  }

  // Send bulk upload notification
  static Future<bool> sendBulkUploadNotificationEmail({
    required String uploadedBy,
    required int questionSetsCount,
    required int totalQuestions,
    required List<String> setNames,
  }) async {
    const adminEmail = "rsaravanan26@gmail.com";
    final subject = 'Bulk Upload Completed - $questionSetsCount Question Sets';
    
    final htmlBody = '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background: #17a2b8; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .info-card { background: #d1ecf1; border: 1px solid #bee5eb; padding: 15px; margin: 15px 0; border-radius: 5px; }
            .footer { background: #f8f9fa; padding: 15px; text-align: center; font-size: 12px; color: #666; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>📁 Wipro Examination Portal</h1>
            <h2>Bulk Upload Notification</h2>
        </div>
        
        <div class="content">
            <p>Dear Administrator,</p>
            
            <p>A bulk upload operation has been completed successfully:</p>
            
            <div class="info-card">
                <h3>📊 Upload Summary:</h3>
                <ul>
                    <li><strong>Uploaded By:</strong> $uploadedBy</li>
                    <li><strong>Question Sets:</strong> $questionSetsCount</li>
                    <li><strong>Total Questions:</strong> $totalQuestions</li>
                    <li><strong>Upload Time:</strong> ${DateTime.now().toString()}</li>
                </ul>
                
                <h4>📋 Question Sets Created:</h4>
                <ul>
                    ${setNames.map((name) => '<li>$name</li>').join('')}
                </ul>
            </div>
            
            <p>All question sets are now available in the admin panel and can be activated for student examinations.</p>
            
            <p>Best regards,<br>
            <strong>Wipro Examination System</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 Wipro Limited. All rights reserved.</p>
        </div>
    </body>
    </html>
    ''';

    return await sendEmail(
      recipientEmail: adminEmail,
      subject: subject,
      htmlBody: htmlBody,
    );
  }
}
