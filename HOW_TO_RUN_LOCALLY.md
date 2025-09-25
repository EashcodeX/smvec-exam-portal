# 🚀 How to Run Wipro Examination Portal Locally

## 📋 Prerequisites

Before running the application, ensure you have the following installed:

### 1. Flutter SDK
- **Download**: [Flutter Official Website](https://flutter.dev/docs/get-started/install)
- **Version**: Flutter 3.8.1 or higher
- **Verify Installation**: Run `flutter --version` in terminal

### 2. Web Browser
- **Chrome** (Recommended for development)
- **Firefox** or **Safari** (Alternative options)

### 3. Code Editor (Optional but Recommended)
- **Visual Studio Code** with Flutter extension
- **Android Studio** with Flutter plugin
- **IntelliJ IDEA** with Flutter plugin

## 🔧 Setup Instructions

### Step 1: Clone/Download the Project
```bash
# If using Git
git clone <repository-url>
cd Examination_portal-main

# Or download and extract the ZIP file
```

### Step 2: Install Dependencies
```bash
# Navigate to project directory
cd Examination_portal-main

# Install Flutter dependencies
flutter pub get
```

### Step 3: Verify Flutter Setup
```bash
# Check Flutter installation
flutter doctor

# Check available devices
flutter devices
```

## 🌐 Running the Application

### Method 1: Default Port (Recommended)
```bash
flutter run -d chrome
```
- **Access URL**: `http://localhost:auto-assigned-port`
- Flutter will automatically assign an available port

### Method 2: Custom Port
```bash
# Run on port 8080
flutter run -d chrome --web-port=8080

# Run on port 3000
flutter run -d chrome --web-port=3000

# Run on port 8083 (current setup)
flutter run -d chrome --web-port=8083
```

### Method 3: Using VS Code
1. Open the project in VS Code
2. Press `F5` or go to `Run > Start Debugging`
3. Select "Chrome" as the device
4. The app will launch automatically

### Method 4: Using Android Studio
1. Open the project in Android Studio
2. Select "Chrome" from the device dropdown
3. Click the "Run" button (green play icon)

## 🔑 Login Credentials

### Admin Login
- **Username**: `admin`
- **Password**: `admin123`
- **Features**: Question management, bulk upload, results download

### Student Login
- **Username**: `student123`, `12345`, or `67890`
- **Password**: `student123`
- **Features**: Take examinations, view results

## 🎯 Application Features

### For Administrators
- ✅ **Question Set Management**: Create and manage question sets
- ✅ **Bulk Upload**: Upload questions via CSV files
- ✅ **Test Activation**: Activate specific question sets for students
- ✅ **Results Download**: Export test results as CSV
- ✅ **Student Analytics**: View performance and malpractice detection

### For Students
- ✅ **Secure Login**: Authentication with register number
- ✅ **Test Instructions**: Clear guidelines before starting
- ✅ **Timed Examinations**: 60-minute test duration
- ✅ **Question Navigation**: Easy navigation between questions
- ✅ **Auto-Submit**: Automatic submission when time expires
- ✅ **Malpractice Detection**: Tab switching monitoring

## 🗂️ Project Structure

```
Examination_portal-main/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── supabase_config.dart      # Database configuration
│   └── pages/
│       ├── login_page.dart       # Login interface
│       ├── admin/
│       │   └── screens/
│       │       └── qs_screen_supabase.dart  # Admin panel
│       └── student/
│           └── screen/
│               ├── instruction.dart         # Test instructions
│               └── test_page_supabase.dart  # Examination interface
├── pubspec.yaml                  # Dependencies
├── sample_questions_template.csv # Bulk upload template
└── BULK_UPLOAD_GUIDE.md         # Bulk upload documentation
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. "Flutter command not found"
```bash
# Add Flutter to your PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Or install Flutter using package manager
# macOS: brew install flutter
# Windows: Use Flutter installer
```

#### 2. "No devices found"
```bash
# Enable web support
flutter config --enable-web

# Check devices again
flutter devices
```

#### 3. "Pub get failed"
```bash
# Clear pub cache
flutter pub cache clean

# Get dependencies again
flutter pub get
```

#### 4. "Chrome not found"
```bash
# Install Chrome browser
# Or use different browser:
flutter run -d web-server --web-port=8080
# Then open http://localhost:8080 in any browser
```

#### 5. Port Already in Use
```bash
# Use different port
flutter run -d chrome --web-port=8081

# Or kill process using the port
# macOS/Linux: lsof -ti:8080 | xargs kill -9
# Windows: netstat -ano | findstr :8080
```

## 🌐 Accessing the Application

### Local Development URLs
- **Default**: `http://localhost:[auto-assigned-port]`
- **Custom Port**: `http://localhost:8080` (or your chosen port)
- **Current Setup**: `http://localhost:8083`

### Network Access (Optional)
To access from other devices on the same network:
```bash
flutter run -d chrome --web-port=8080 --web-hostname=0.0.0.0
```
Then access via: `http://[your-ip-address]:8080`

## 📱 Platform Support

### Supported Platforms
- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Windows Desktop**
- ✅ **macOS Desktop**
- ✅ **Linux Desktop**
- ✅ **Android** (with additional setup)
- ✅ **iOS** (with additional setup)

### Running on Different Platforms
```bash
# Web (default)
flutter run -d chrome

# Windows Desktop
flutter run -d windows

# macOS Desktop
flutter run -d macos

# Linux Desktop
flutter run -d linux
```

## 🔄 Development Workflow

### Hot Reload
While the app is running, you can make changes and see them instantly:
- Press `r` in the terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Debugging
- Press `d` to detach (keep app running)
- Press `h` to see all available commands
- Use browser developer tools for web debugging

## 📊 Database Information

### Backend: Supabase
- **Type**: PostgreSQL database
- **Features**: Real-time updates, authentication, file storage
- **Configuration**: Located in `lib/supabase_config.dart`

### Sample Data Included
- Admin account with credentials
- Sample student accounts
- Sample question sets for testing

## 🎓 Getting Started Guide

1. **Install Flutter** following the official guide
2. **Download/Clone** this project
3. **Run** `flutter pub get` to install dependencies
4. **Execute** `flutter run -d chrome --web-port=8080`
5. **Open** `http://localhost:8080` in your browser
6. **Login** with admin credentials to explore features
7. **Test** student login and examination flow

## 📞 Support

If you encounter any issues:
1. Check this troubleshooting guide
2. Verify Flutter installation with `flutter doctor`
3. Ensure all dependencies are installed with `flutter pub get`
4. Try running on a different port
5. Check browser console for error messages

## ⚡ Quick Start (TL;DR)

For experienced developers who want to get started immediately:

```bash
# 1. Install Flutter (if not already installed)
# Download from: https://flutter.dev/docs/get-started/install

# 2. Navigate to project directory
cd Examination_portal-main

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run -d chrome --web-port=8080

# 5. Open browser and go to: http://localhost:8080

# 6. Login credentials:
# Admin: admin / admin123
# Student: student123 / student123
```

## 📋 System Requirements

### Minimum Requirements
- **RAM**: 4GB (8GB recommended)
- **Storage**: 2GB free space
- **OS**: Windows 10+, macOS 10.14+, or Linux (64-bit)
- **Internet**: Required for initial setup and Supabase connection

### Recommended Setup
- **RAM**: 8GB or more
- **CPU**: Multi-core processor
- **Browser**: Latest Chrome for best performance
- **Editor**: VS Code with Flutter extension

---

**🎉 You're all set!** The Wipro Examination Portal should now be running locally on your machine.

**📚 Additional Resources:**
- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Bulk Upload Guide](./BULK_UPLOAD_GUIDE.md)
