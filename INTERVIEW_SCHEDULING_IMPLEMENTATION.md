# Interview Scheduling with Zoom Integration - Implementation Summary

## Overview
Implemented a complete interview scheduling system for shortlisted candidates with Zoom meeting integration and email notifications.

## Features Implemented

### 1. Backend Components

#### Configuration Updates
- **File**: `backend/core/config.py`
  - Updated Zoom configuration to use Server-to-Server OAuth
  - Added: `ZOOM_ACCOUNT_ID`, `ZOOM_CLIENT_ID`, `ZOOM_CLIENT_SECRET`
  
- **File**: `backend/.env`
  - Added Zoom credentials:
    - ZOOM_ENABLED=true
    - ZOOM_ACCOUNT_ID=eApapCraT066pxBTAKf1qA
    - ZOOM_CLIENT_ID=jAibQccwTpms9hDzAZt67Q
    - ZOOM_CLIENT_SECRET=kkKsOR5xant1SduhQwfipkW9DEKxM81A

#### New Services

1. **ZoomService** (`backend/application/services/zoom_service.py`)
   - Implements Server-to-Server OAuth authentication
   - Creates Zoom meetings programmatically
   - Methods:
     - `get_access_token()`: Obtains OAuth token from Zoom
     - `create_meeting(topic, start_time, duration)`: Creates a scheduled Zoom meeting
   - Returns join URL for candidates

2. **EmailService** (`backend/application/services/email_service.py`)
   - Sends interview invitation emails to candidates
   - Methods:
     - `send_email()`: Generic email sending
     - `send_interview_invitation()`: Sends formatted interview invitation with meeting link
   - Supports both plain text and HTML emails

#### New API Router

**File**: `backend/api/routers/shortlisted_candidates.py`

Endpoints:
1. `GET /api/v1/shortlisted-candidates/`
   - Lists all shortlisted candidates
   - Filters: department, job_posting_id
   - Returns application details with candidate and job info

2. `POST /api/v1/shortlisted-candidates/{application_id}/create-interview`
   - Creates interview and generates meeting link
   - Parameters:
     - meeting_platform: "zoom", "teams", or "both"
     - scheduled_date: Interview date/time
     - duration_minutes: Interview duration
     - round_number: Interview round
     - round_name: Name of the interview round
     - interviewer_ids: List of interviewer user IDs
   - Actions:
     - Creates Zoom meeting
     - Saves interview record to database
     - Updates application status to "interview"
     - Sends email invitation to candidate
   - Returns meeting links and interview ID

3. `GET /api/v1/shortlisted-candidates/departments`
   - Returns list of departments with shortlisted candidates

4. `GET /api/v1/shortlisted-candidates/job-postings`
   - Returns job postings with shortlisted candidates
   - Optional filter: department

#### Main App Updates
- **File**: `backend/main.py`
  - Added shortlisted_candidates router
  - Endpoint prefix: `/api/v1/shortlisted-candidates`

### 2. Frontend Components

#### New Screen

**File**: `frontend/lib/presentation/screens/interviews/shortlisted_candidates_screen.dart`

Features:
- **Filters**:
  - Department dropdown (All Departments + specific departments)
  - Job Posting dropdown (All Positions + specific positions)
  - Cascading filters (selecting department updates job postings)

- **Candidate List**:
  - Displays shortlisted candidates with:
    - Candidate name
    - Job title
    - Application date
    - AI match score (if available)
    - Status badge
  - "Create Interview" button for each candidate

- **Create Interview Dialog**:
  - Meeting platform selection (Zoom, Teams, Both)
  - Interview round name input
  - Date picker
  - Time picker
  - Duration dropdown (30min, 45min, 1hr, 1.5hr, 2hr)
  - Submits to backend API

#### Navigation Updates

1. **Dashboard Sidebar** (`frontend/lib/presentation/screens/dashboard/dashboard_screen.dart`)
   - Added "Shortlisted Candidates" menu item
   - Icon: checklist_outlined
   - Position: Between "Interviews" and "Offers"

2. **Main App Routes** (`frontend/lib/main.dart`)
   - Added route: `/shortlisted-candidates`
   - Imported ShortlistedCandidatesScreen

## User Flow

1. **Access Screen**: User clicks "Shortlisted Candidates" in dashboard sidebar
2. **Filter Candidates**: 
   - Select department (optional)
   - Select job posting (optional)
   - View filtered list of shortlisted candidates
3. **Schedule Interview**:
   - Click "Create Interview" button for a candidate
   - Dialog opens with scheduling options
   - Select meeting platform (Zoom/Teams/Both)
   - Choose date and time
   - Set interview duration
   - Enter round name
   - Click "Schedule Interview"
4. **Backend Processing**:
   - Creates Zoom meeting via API
   - Saves interview record
   - Updates application status to "interview"
   - Sends email invitation to candidate with meeting link
5. **Confirmation**: Success message shown to user

## Technical Details

### Zoom Integration
- Uses **Server-to-Server OAuth** (not JWT which is deprecated)
- Authentication flow:
  1. Base64 encode client_id:client_secret
  2. POST to https://zoom.us/oauth/token with account_credentials grant
  3. Receive access token
  4. Use token to create meetings via /users/me/meetings endpoint

### Email Notifications
- SMTP-based email service
- Configurable via environment variables
- Falls back to logging if EMAIL_ENABLED=false
- Sends both plain text and HTML formatted emails

### Database Updates
- Uses existing Interview model
- Links to Application via application_id
- Stores video_link (Zoom join URL)
- Updates application status automatically

## Environment Variables Required

```env
# Zoom Configuration
ZOOM_ENABLED=true
ZOOM_ACCOUNT_ID=your_account_id
ZOOM_CLIENT_ID=your_client_id
ZOOM_CLIENT_SECRET=your_client_secret

# Email Configuration (Optional but recommended)
EMAIL_ENABLED=true
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_FROM_EMAIL=noreply@agentichr.com
SMTP_FROM_NAME=AgenticHR
```

## Testing

To test the implementation:

1. Ensure backend is running with Zoom credentials configured
2. Create some job applications and mark them as "shortlisted"
3. Navigate to "Shortlisted Candidates" screen
4. Click "Create Interview" on a candidate
5. Fill in the dialog and submit
6. Verify:
   - Zoom meeting is created
   - Interview record is saved
   - Application status is updated
   - Email is sent (check logs if EMAIL_ENABLED=false)

## Future Enhancements

1. **Microsoft Teams Integration**: Implement Teams meeting creation
2. **Calendar Integration**: Add to Google Calendar/Outlook
3. **Interviewer Selection**: UI to select specific interviewers
4. **Interview Panel**: Assign multiple interviewers with roles
5. **Reminder Emails**: Send automated reminders before interviews
6. **Rescheduling**: Allow rescheduling from the UI
7. **Interview Feedback**: Direct link to feedback form in invitation

## Files Modified/Created

### Backend
- ✅ `backend/core/config.py` (modified)
- ✅ `backend/.env` (modified)
- ✅ `backend/application/services/zoom_service.py` (created)
- ✅ `backend/application/services/email_service.py` (created)
- ✅ `backend/api/routers/shortlisted_candidates.py` (created)
- ✅ `backend/main.py` (modified)

### Frontend
- ✅ `frontend/lib/presentation/screens/interviews/shortlisted_candidates_screen.dart` (created)
- ✅ `frontend/lib/presentation/screens/dashboard/dashboard_screen.dart` (modified)
- ✅ `frontend/lib/main.dart` (modified)

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/shortlisted-candidates/` | List shortlisted candidates |
| POST | `/api/v1/shortlisted-candidates/{id}/create-interview` | Create interview with meeting |
| GET | `/api/v1/shortlisted-candidates/departments` | Get departments list |
| GET | `/api/v1/shortlisted-candidates/job-postings` | Get job postings list |

## Notes

- The Zoom credentials provided are for development/testing
- Email service can be disabled for testing (logs to console instead)
- Teams integration is prepared but not yet implemented
- All timestamps are in UTC
- Interview duration defaults to 60 minutes
