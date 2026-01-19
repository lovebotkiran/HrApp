# AgenticHR - AI-Powered Recruitment Management System

A comprehensive recruitment management application built with Flutter (frontend) and FastAPI (backend), featuring AI-powered candidate matching, resume parsing, and automated workflows.

## 🚀 Features

### ✅ Implemented Core Features

1. **Job Requisition Management**
   - Create and manage job requisitions
   - Multi-level approval workflow (Manager → HR → Director)
   - AI-powered job description generation
   - Track requisition status

2. **Job Posting**
   - Publish jobs to multiple platforms
   - Auto-expiry management
   - Track views and applications

3. **Candidate Management**
   - Candidate profile creation
   - Resume upload and parsing
   - Duplicate detection
   - Skills extraction

4. **Application Processing**
   - Online application submission
   - AI match scoring against job descriptions
   - Source tracking

5. **Interview Management**
   - Multi-round interview scheduling
   - Interviewer assignment
   - Feedback collection and rating system
   - Rescheduling support

6. **Offer Management**
   - Offer letter generation
   - Multi-level approval workflow
   - Digital signature support
   - Offer acceptance tracking

7. **Dashboard & Analytics**
   - Recruitment pipeline visualization
   - Key metrics and statistics
   - Recent activity tracking

### 🔄 Optional Integrations (Configurable)

- AWS S3 for document storage
- Email notifications (SMTP)
- SMS notifications (Twilio)
- WhatsApp notifications
- Calendar integration (Google/Outlook)
- Video conferencing (Zoom/Meet/Teams)
- Job board posting (LinkedIn, etc.)

## 🏗️ Architecture

### Backend (FastAPI - Clean Architecture)

```
backend/
├── core/                    # Core configuration
│   └── config.py
├── domain/                  # Business logic layer
│   ├── entities/
│   ├── repositories/
│   └── services/
├── application/             # Application layer
│   ├── schemas.py          # Pydantic models
│   └── use_cases/
├── infrastructure/          # Infrastructure layer
│   ├── database/
│   │   ├── connection.py
│   │   └── models.py       # SQLAlchemy models
│   ├── security/
│   │   └── auth.py
│   └── external_services/
├── api/                     # Presentation layer
│   └── routers/            # API endpoints
└── main.py                 # Application entry point
```

### Frontend (Flutter - Clean Architecture)

```
frontend/
├── lib/
│   ├── core/
│   │   └── theme/          # App theming
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── presentation/
│   │   ├── screens/        # UI screens
│   │   ├── widgets/        # Reusable widgets
│   │   └── providers/      # State management
│   └── main.dart
└── pubspec.yaml
```

## 📦 Installation

### Prerequisites

- Python 3.10+
- PostgreSQL 14+
- Flutter 3.0+
- Redis (for background tasks)

### Backend Setup

1. **Create virtual environment**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Setup database**
   ```bash
   # Create PostgreSQL database
   createdb agentichr
   
   # Run migrations
   psql -U postgres -d agentichr -f ../database/schema.sql
   psql -U postgres -d agentichr -f ../database/seed_data.sql
   ```

5. **Run the server**
   ```bash
   python main.py
   # Or with uvicorn
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### Frontend Setup

1. **Install dependencies**
   ```bash
   cd frontend
   flutter pub get
   ```

2. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # For mobile (Android)
   flutter run -d android
   
   # For mobile (iOS)
   flutter run -d ios
   ```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the `backend` directory:

```env
# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/agentichr

# JWT
JWT_SECRET_KEY=your-secret-key-here

# Optional: AWS S3
S3_ENABLED=false
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_REGION=ap-south-1

# Optional: Email
EMAIL_ENABLED=false
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-password

# Optional: SMS
SMS_ENABLED=false
TWILIO_ACCOUNT_SID=your-sid
TWILIO_AUTH_TOKEN=your-token

# AI Configuration
AI_ENABLED=true
RESUME_PARSING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

## 🎨 Design System

### Color Palette

- **Primary**: #04A1FF (Blue)
- **Success**: #10B981 (Green)
- **Warning**: #F59E0B (Orange)
- **Error**: #EF4444 (Red)
- **Info**: #3B82F6 (Light Blue)

### Typography

- **Font Family**: Inter
- **Headings**: Bold (700)
- **Body**: Regular (400)
- **Labels**: Medium (500)

## 📱 Responsive Design

The application is fully responsive with breakpoints:

- **Mobile**: < 450px
- **Tablet**: 451px - 800px
- **Desktop**: 801px - 1920px
- **4K**: > 1920px

## 🔐 Authentication

Default admin credentials (change in production):

- **Email**: admin@agentichr.com
- **Password**: Admin@123

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest tests/ --cov=.
```

### Frontend Tests
```bash
cd frontend
flutter test
```

## 📚 API Documentation

Once the backend is running, access the API documentation at:

- **Swagger UI**: http://localhost:8000/api/v1/docs
- **ReDoc**: http://localhost:8000/api/v1/redoc

## 🚧 Development Roadmap

- [ ] Complete all API endpoints
- [ ] Implement AI resume parsing
- [ ] Add real-time notifications
- [ ] Implement chatbot
- [ ] Add video interview recording
- [ ] Complete onboarding workflows
- [ ] Add referral management
- [ ] Implement GDPR compliance features
- [ ] Add multi-language support

## 📄 License

This project is proprietary software. All rights reserved.

## 👥 Support

For support, email support@agentichr.com or create an issue in the repository.

## 🙏 Acknowledgments

- FastAPI for the excellent Python web framework
- Flutter for the cross-platform UI framework
- Open-source AI models for resume parsing and matching
