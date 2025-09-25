#!/bin/bash

# Wipro Examination Portal - Production Preparation Script
# This script prepares your Flutter app for production deployment

echo "🚀 Preparing Wipro Examination Portal for Production..."
echo "================================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    exit 1
fi

print_status "Flutter is installed"

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
print_info "Flutter version: $FLUTTER_VERSION"

# Clean previous builds
print_info "Cleaning previous builds..."
flutter clean
print_status "Previous builds cleaned"

# Get dependencies
print_info "Getting dependencies..."
flutter pub get
print_status "Dependencies updated"

# Run Flutter doctor
print_info "Running Flutter doctor..."
flutter doctor

# Check for web support
if ! flutter devices | grep -q "Chrome"; then
    print_warning "Chrome not detected. Web deployment may not work properly."
else
    print_status "Chrome detected for web development"
fi

# Create production configuration
print_info "Creating production configuration..."

# Create config directory if it doesn't exist
mkdir -p lib/config

# Create production config file
cat > lib/config/production_config.dart << 'EOF'
// Production Configuration for Wipro Examination Portal
class ProductionConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );
  
  // App Configuration
  static const String appName = 'Wipro Examination Portal';
  static const String appVersion = '1.0.0';
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);

  // Security Configuration
  static const int sessionTimeoutMinutes = 120; // 2 hours
  static const int maxLoginAttempts = 3;
  static const bool enableMalpracticeDetection = true;

  // Performance Configuration
  static const int maxConcurrentUsers = 1000;
  static const int cacheTimeoutMinutes = 30;

  // Contact Information
  static const String supportEmail = 'support@wipro.com';
  static const String instituteName = 'Wipro Limited';
}
EOF

print_status "Production configuration created"

# Create environment template
print_info "Creating environment template..."

cat > .env.example << 'EOF'
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Production Settings
PRODUCTION=true
ENABLE_ANALYTICS=true

# Optional: Analytics
GOOGLE_ANALYTICS_ID=GA_MEASUREMENT_ID
SENTRY_DSN=https://your-sentry-dsn

# Optional: Custom Domain
CUSTOM_DOMAIN=exam.smvec.ac.in
EOF

print_status "Environment template created (.env.example)"

# Update web/index.html for production
print_info "Updating web configuration for production..."

# Backup original index.html
cp web/index.html web/index.html.backup

# Update index.html with production optimizations
cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <!--
    If you are serving your web app in a path other than the root, change the
    href value below to reflect the base path you are serving from.

    The path provided below has to start and end with a slash "/" in order for
    it to work correctly.

    For more details:
    * https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base

    This is a placeholder for base href that will be replaced by the value of
    the `--base-href` argument provided to `flutter build`.
  -->
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Wipro Online Examination Portal">
  <meta name="keywords" content="examination, online test, Wipro, assessment">
  <meta name="author" content="Wipro Limited">

  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Wipro Exam Portal">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <!-- Security Headers -->
  <meta http-equiv="Content-Security-Policy" 
        content="default-src 'self'; 
                 script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com;
                 style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
                 font-src 'self' https://fonts.gstatic.com;
                 connect-src 'self' https://*.supabase.co https://www.google-analytics.com;
                 img-src 'self' data: https:;">

  <!-- Performance optimizations -->
  <meta http-equiv="Cache-Control" content="public, max-age=31536000">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

  <title>Wipro Examination Portal</title>
  <link rel="manifest" href="manifest.json">

  <script>
    // Service worker registration
    if ('serviceWorker' in navigator) {
      window.addEventListener('flutter-first-frame', function () {
        navigator.serviceWorker.register('flutter_service_worker.js');
      });
    }
  </script>
</head>
<body>
  <!-- Loading indicator -->
  <div id="loading" style="
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    color: white;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    z-index: 9999;
  ">
    <div style="
      width: 50px;
      height: 50px;
      border: 3px solid rgba(255,255,255,0.3);
      border-top: 3px solid white;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-bottom: 20px;
    "></div>
    <h2 style="margin: 0; font-weight: 300;">Wipro Exam Portal</h2>
    <p style="margin: 10px 0 0 0; opacity: 0.8;">Loading Examination Portal...</p>
  </div>

  <style>
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>

  <script src="flutter.js" defer></script>
  <script>
    window.addEventListener('load', function(ev) {
      // Hide loading indicator when app loads
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine().then(function(appRunner) {
            document.getElementById('loading').style.display = 'none';
            appRunner.runApp();
          });
        }
      });
    });
  </script>
</body>
</html>
EOF

print_status "Web configuration updated for production"

# Create deployment scripts
print_info "Creating deployment scripts..."

# Vercel deployment script
cat > deploy_vercel.sh << 'EOF'
#!/bin/bash
echo "🚀 Deploying to Vercel..."

# Build for production
flutter build web --release --dart-define=PRODUCTION=true

# Deploy to Vercel
cd build/web
vercel --prod

echo "✅ Deployment to Vercel completed!"
EOF

chmod +x deploy_vercel.sh

# Firebase deployment script
cat > deploy_firebase.sh << 'EOF'
#!/bin/bash
echo "🚀 Deploying to Firebase..."

# Build for production
flutter build web --release --dart-define=PRODUCTION=true

# Deploy to Firebase
firebase deploy

echo "✅ Deployment to Firebase completed!"
EOF

chmod +x deploy_firebase.sh

print_status "Deployment scripts created"

# Create GitHub Actions workflow
print_info "Creating GitHub Actions workflow..."

mkdir -p .github/workflows

cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy Wipro Examination Portal to Production

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run tests
      run: flutter test
      
    - name: Analyze code
      run: flutter analyze

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build for web
      run: flutter build web --release --dart-define=PRODUCTION=true
      
    - name: Deploy to Vercel
      uses: amondnet/vercel-action@v20
      with:
        vercel-token: ${{ secrets.VERCEL_TOKEN }}
        vercel-org-id: ${{ secrets.ORG_ID }}
        vercel-project-id: ${{ secrets.PROJECT_ID }}
        working-directory: ./build/web
EOF

print_status "GitHub Actions workflow created"

# Build for production
print_info "Building for production..."
flutter build web --release --dart-define=PRODUCTION=true

if [ $? -eq 0 ]; then
    print_status "Production build completed successfully!"
else
    print_error "Production build failed!"
    exit 1
fi

# Final instructions
echo ""
echo "🎉 Production preparation completed!"
echo "=================================="
echo ""
print_info "Next steps:"
echo "1. Update .env.example with your actual Supabase credentials"
echo "2. Choose a hosting platform (Vercel recommended)"
echo "3. Set up your production Supabase database"
echo "4. Configure your custom domain (optional)"
echo "5. Deploy using one of the provided scripts"
echo ""
print_info "Deployment options:"
echo "• Vercel: Run ./deploy_vercel.sh"
echo "• Firebase: Run ./deploy_firebase.sh"
echo "• Manual: Upload build/web folder to your hosting provider"
echo ""
print_info "Production build location: build/web/"
echo ""
print_status "Your Wipro Examination Portal is ready for production! 🚀"
EOF
