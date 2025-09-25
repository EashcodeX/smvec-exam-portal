# Production Hosting Guide - Wipro Examination Portal

## 🚀 **Recommended Hosting Solutions**

### **Option 1: Vercel + Supabase (RECOMMENDED) ⭐**

**Best for**: Easy deployment, automatic scaling, global CDN

#### **Why Vercel?**
- ✅ **Free tier available** with generous limits
- ✅ **Automatic deployments** from GitHub
- ✅ **Global CDN** for fast loading worldwide
- ✅ **HTTPS by default** with custom domains
- ✅ **Zero configuration** for Flutter web apps
- ✅ **Perfect integration** with Supabase

#### **Deployment Steps:**

1. **Prepare Flutter for Web Production**
```bash
# Build for production
flutter build web --release

# Optimize for web
flutter build web --web-renderer html --release
```

2. **Setup GitHub Repository**
```bash
# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit"

# Push to GitHub
git remote add origin https://github.com/yourusername/saarthi-examination-portal.git
git push -u origin main
```

3. **Deploy to Vercel**
- Visit [vercel.com](https://vercel.com)
- Sign up with GitHub account
- Click "New Project"
- Import your repository
- Configure build settings:
  - **Build Command**: `flutter build web --release`
  - **Output Directory**: `build/web`
  - **Install Command**: `flutter pub get`

4. **Custom Domain (Optional)**
- Add your domain in Vercel dashboard
- Update DNS records as instructed
- Automatic HTTPS certificate

#### **Cost**: FREE for most use cases

---

### **Option 2: Firebase Hosting + Supabase**

**Best for**: Google ecosystem integration, easy scaling

#### **Deployment Steps:**

1. **Install Firebase CLI**
```bash
npm install -g firebase-tools
firebase login
```

2. **Initialize Firebase Hosting**
```bash
firebase init hosting
# Select build/web as public directory
# Configure as single-page app: Yes
```

3. **Build and Deploy**
```bash
flutter build web --release
firebase deploy
```

#### **Cost**: FREE tier (1GB storage, 10GB/month transfer)

---

### **Option 3: Netlify + Supabase**

**Best for**: Simple deployment, form handling, serverless functions

#### **Deployment Steps:**

1. **Build for Production**
```bash
flutter build web --release
```

2. **Deploy via Drag & Drop**
- Visit [netlify.com](https://netlify.com)
- Drag `build/web` folder to deploy area
- Get instant URL

3. **Continuous Deployment**
- Connect GitHub repository
- Auto-deploy on git push

#### **Cost**: FREE tier available

---

## 🔧 **Production Preparation Checklist**

### **1. Environment Configuration**

Create production environment file:

```dart
// lib/config/production_config.dart
class ProductionConfig {
  static const String supabaseUrl = 'YOUR_PRODUCTION_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_PRODUCTION_SUPABASE_ANON_KEY';
  static const bool isProduction = true;
  static const String appName = 'Wipro Examination Portal';
}
```

### **2. Supabase Production Setup**

#### **Database Security**
```sql
-- Enable Row Level Security on all tables
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_test ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_submissions ENABLE ROW LEVEL SECURITY;

-- Create security policies
CREATE POLICY "Admins can manage everything" ON admins
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Students can read their own data" ON students
  FOR SELECT USING (auth.uid()::text = id::text);
```

#### **Production Database**
- Create new Supabase project for production
- Import your schema and data
- Configure environment variables
- Set up database backups

### **3. Security Hardening**

#### **API Keys Management**
```dart
// Use environment variables
class Config {
  static String get supabaseUrl => 
    const String.fromEnvironment('SUPABASE_URL', defaultValue: 'dev-url');
  static String get supabaseKey => 
    const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'dev-key');
}
```

#### **Content Security Policy**
Add to `web/index.html`:
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline' 'unsafe-eval';
               style-src 'self' 'unsafe-inline';
               connect-src 'self' https://*.supabase.co;">
```

### **4. Performance Optimization**

#### **Build Optimization**
```bash
# Optimize bundle size
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false

# Enable tree shaking
flutter build web --release --tree-shake-icons

# Optimize for web
flutter build web --web-renderer html --release
```

#### **Caching Strategy**
Add to `web/index.html`:
```html
<meta http-equiv="Cache-Control" content="public, max-age=31536000">
```

### **5. Monitoring & Analytics**

#### **Error Tracking**
```dart
// Add Sentry or similar
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await SentryFlutter.init(
    (options) => options.dsn = 'YOUR_SENTRY_DSN',
    appRunner: () => runApp(MyApp()),
  );
}
```

#### **Usage Analytics**
```dart
// Add Google Analytics
import 'package:google_analytics/google_analytics.dart';

GoogleAnalytics.initialize(trackingId: 'GA_TRACKING_ID');
```

---

## 🌐 **Domain & SSL Setup**

### **Custom Domain Configuration**

1. **Purchase Domain** (recommended providers):
   - Namecheap (~$10/year)
   - GoDaddy (~$15/year)
   - Google Domains (~$12/year)

2. **DNS Configuration**:
```
Type: CNAME
Name: www
Value: your-app.vercel.app

Type: A
Name: @
Value: 76.76.19.61 (Vercel IP)
```

3. **SSL Certificate**: Automatic with Vercel/Netlify/Firebase

---

## 💰 **Cost Breakdown**

### **Minimal Setup (FREE)**
- **Hosting**: Vercel/Netlify/Firebase (Free tier)
- **Database**: Supabase (Free tier - 500MB, 2GB bandwidth)
- **Domain**: Use provided subdomain
- **Total**: $0/month

### **Professional Setup (~$15/month)**
- **Hosting**: Vercel Pro ($20/month) or Firebase Blaze (pay-as-you-go)
- **Database**: Supabase Pro ($25/month)
- **Domain**: Custom domain ($10-15/year)
- **CDN**: Included with hosting
- **Total**: ~$15-45/month

### **Enterprise Setup (~$100/month)**
- **Hosting**: Vercel Enterprise or dedicated server
- **Database**: Supabase Team ($599/month) or dedicated PostgreSQL
- **Monitoring**: Sentry, DataDog
- **Backup**: Automated daily backups
- **Support**: Priority support

---

## 🔒 **Security Considerations**

### **Authentication Security**
- ✅ Use strong password policies
- ✅ Implement session timeouts
- ✅ Add rate limiting for login attempts
- ✅ Enable two-factor authentication for admins

### **Data Protection**
- ✅ Encrypt sensitive data at rest
- ✅ Use HTTPS everywhere
- ✅ Implement proper CORS policies
- ✅ Regular security audits

### **Exam Security**
- ✅ Implement anti-cheating measures
- ✅ Monitor tab switching/window focus
- ✅ Time-based session management
- ✅ IP-based access control (if needed)

---

## 📊 **Scalability Planning**

### **Expected Load**
- **Students**: 500-5000 concurrent users
- **Bandwidth**: 10-100GB/month
- **Database**: 1-10GB storage
- **Requests**: 100K-1M/month

### **Scaling Strategy**
1. **Start with free tiers** for testing
2. **Monitor usage** and upgrade as needed
3. **Use CDN** for static assets
4. **Implement caching** for database queries
5. **Consider load balancing** for high traffic

---

## 🚀 **Quick Start Deployment**

### **1-Click Vercel Deployment**
```bash
# Install Vercel CLI
npm i -g vercel

# Build and deploy
flutter build web --release
cd build/web
vercel --prod
```

### **GitHub Actions CI/CD**
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
```

**Your examination portal is ready for production deployment!** 🎉
