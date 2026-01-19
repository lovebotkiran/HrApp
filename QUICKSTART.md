# AgenticHR - Quick Start Guide

## Prerequisites

- Python 3.10+
- PostgreSQL 14+
- Flutter 3.0+ (for frontend)
- Redis (optional, for background tasks)

## Backend Setup

### Option 1: Automated Setup (Recommended)

```bash
cd backend
./setup.sh
```

This will:
- Create a virtual environment
- Install all dependencies
- Create .env file from template

### Option 2: Manual Setup

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install --upgrade pip
pip install psycopg2-binary
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env with your configuration
```

### Database Setup

```bash
# Create database
createdb agentichr

# Run schema
psql -U postgres -d agentichr -f database/schema.sql

# Load seed data
psql -U postgres -d agentichr -f database/seed_data.sql
```

### Run Backend

```bash
cd backend
source venv/bin/activate
python main.py
```

Backend will be available at: http://localhost:8000

API Documentation:
- Swagger UI: http://localhost:8000/api/v1/docs
- ReDoc: http://localhost:8000/api/v1/redoc

## Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile
flutter run -d android  # or ios
```

## Docker Setup (Alternative)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Default Credentials

- **Email**: admin@agentichr.com
- **Password**: Admin@123

⚠️ **Change these credentials in production!**

## API Endpoints Overview

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `GET /api/v1/auth/me` - Get current user

### Job Requisitions
- `POST /api/v1/job-requisitions/` - Create requisition
- `GET /api/v1/job-requisitions/` - List requisitions
- `POST /api/v1/job-requisitions/{id}/approve` - Approve/reject
- `POST /api/v1/job-requisitions/{id}/generate-jd` - Generate JD

### Job Postings
- `POST /api/v1/job-postings/` - Create posting
- `GET /api/v1/job-postings/` - List postings (public)
- `POST /api/v1/job-postings/{id}/publish` - Publish to platforms

### Candidates
- `POST /api/v1/candidates/` - Create candidate
- `GET /api/v1/candidates/` - List candidates
- `POST /api/v1/candidates/{id}/upload-resume` - Upload resume
- `POST /api/v1/candidates/{id}/parse-resume` - Parse resume

### Applications
- `POST /api/v1/applications/` - Submit application
- `GET /api/v1/applications/` - List applications
- `PUT /api/v1/applications/{id}/status` - Update status
- `POST /api/v1/applications/{id}/shortlist` - Shortlist

### Interviews
- `POST /api/v1/interviews/` - Schedule interview
- `GET /api/v1/interviews/` - List interviews
- `POST /api/v1/interviews/{id}/feedback` - Submit feedback
- `POST /api/v1/interviews/{id}/reschedule` - Reschedule

### Offers
- `POST /api/v1/offers/` - Create offer
- `GET /api/v1/offers/` - List offers
- `POST /api/v1/offers/{id}/approve` - Approve offer
- `POST /api/v1/offers/{id}/send` - Send to candidate
- `POST /api/v1/offers/{id}/accept` - Accept/reject (public)

### Dashboard
- `GET /api/v1/dashboard/pipeline` - Pipeline stats
- `GET /api/v1/dashboard/metrics` - Recruitment metrics

## Troubleshooting

### PostgreSQL Connection Error

Make sure PostgreSQL is running and credentials in `.env` are correct:

```bash
# Check if PostgreSQL is running
pg_isready

# Start PostgreSQL (macOS)
brew services start postgresql
```

### Module Not Found Error

Activate virtual environment:

```bash
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### Port Already in Use

Change port in `main.py` or kill the process using port 8000:

```bash
# Find process
lsof -i :8000

# Kill process
kill -9 <PID>
```

## Development

### Running Tests

```bash
# Backend
cd backend
pytest tests/ --cov=.

# Frontend
cd frontend
flutter test
```

### Code Formatting

```bash
# Backend
black .
isort .

# Frontend
flutter format .
```

## Production Deployment

See [README.md](README.md) for production deployment instructions.

## Support

For issues or questions:
- Check [FUNCTIONALITIES.md](FUNCTIONALITIES.md) for feature reference
- Review [walkthrough.md](walkthrough.md) for implementation details
- Create an issue in the repository
