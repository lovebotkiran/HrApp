# API Endpoints Summary - AgenticHR

## Total Endpoints Implemented: 70+

### ✅ Authentication (5 endpoints)
- POST `/api/v1/auth/register` - Register new user
- POST `/api/v1/auth/login` - Login and get tokens
- POST `/api/v1/auth/refresh` - Refresh access token
- GET `/api/v1/auth/me` - Get current user info
- POST `/api/v1/auth/logout` - Logout

### ✅ Job Requisitions (7 endpoints)
- POST `/api/v1/job-requisitions/` - Create requisition
- GET `/api/v1/job-requisitions/` - List with filters
- GET `/api/v1/job-requisitions/{id}` - Get details
- PUT `/api/v1/job-requisitions/{id}` - Update
- DELETE `/api/v1/job-requisitions/{id}` - Delete (soft)
- POST `/api/v1/job-requisitions/{id}/approve` - Approve/reject
- POST `/api/v1/job-requisitions/{id}/generate-jd` - AI generate JD

### ✅ Job Postings (8 endpoints)
- POST `/api/v1/job-postings/` - Create posting
- GET `/api/v1/job-postings/` - List (public, with filters)
- GET `/api/v1/job-postings/{id}` - Get details (increments views)
- PUT `/api/v1/job-postings/{id}` - Update
- DELETE `/api/v1/job-postings/{id}` - Deactivate
- POST `/api/v1/job-postings/{id}/publish` - Publish to platforms
- GET `/api/v1/job-postings/{id}/platforms` - Get platforms
- POST `/api/v1/job-postings/{id}/expire` - Expire manually

### ✅ Candidates (9 endpoints)
- POST `/api/v1/candidates/` - Create candidate (duplicate check)
- GET `/api/v1/candidates/` - List with advanced filters
- GET `/api/v1/candidates/{id}` - Get profile
- PUT `/api/v1/candidates/{id}` - Update profile
- DELETE `/api/v1/candidates/{id}` - Delete (cascade)
- POST `/api/v1/candidates/{id}/upload-resume` - Upload resume
- POST `/api/v1/candidates/{id}/parse-resume` - AI parse resume
- POST `/api/v1/candidates/{id}/blacklist` - Blacklist with reason
- POST `/api/v1/candidates/{id}/unblacklist` - Remove from blacklist
- GET `/api/v1/candidates/{id}/documents` - Get all documents

### ✅ Applications (9 endpoints)
- POST `/api/v1/applications/` - Submit application
- GET `/api/v1/applications/` - List with filters
- GET `/api/v1/applications/{id}` - Get details
- PUT `/api/v1/applications/{id}/status` - Update status
- POST `/api/v1/applications/{id}/shortlist` - Shortlist
- POST `/api/v1/applications/{id}/reject` - Reject
- POST `/api/v1/applications/{id}/assessment` - Create assessment
- GET `/api/v1/applications/{id}/assessments` - Get assessments
- POST `/api/v1/applications/{id}/calculate-match-score` - AI match score

### ✅ Interviews (11 endpoints)
- POST `/api/v1/interviews/` - Schedule interview
- GET `/api/v1/interviews/` - List with filters
- GET `/api/v1/interviews/{id}` - Get details
- PUT `/api/v1/interviews/{id}` - Update
- POST `/api/v1/interviews/{id}/reschedule` - Reschedule
- POST `/api/v1/interviews/{id}/cancel` - Cancel
- POST `/api/v1/interviews/{id}/complete` - Mark complete
- POST `/api/v1/interviews/{id}/feedback` - Submit feedback
- GET `/api/v1/interviews/{id}/feedback` - Get all feedback (with averages)
- GET `/api/v1/interviews/{id}/panel` - Get panel members

### ✅ Offers (11 endpoints)
- POST `/api/v1/offers/` - Create offer
- GET `/api/v1/offers/` - List with filters
- GET `/api/v1/offers/{id}` - Get details
- PUT `/api/v1/offers/{id}` - Update
- POST `/api/v1/offers/{id}/approve` - Approve/reject
- POST `/api/v1/offers/{id}/send` - Send to candidate
- POST `/api/v1/offers/{id}/accept` - Accept/reject (public)
- POST `/api/v1/offers/{id}/revise` - Create revised offer
- POST `/api/v1/offers/{id}/withdraw` - Withdraw offer
- GET `/api/v1/offers/{id}/approvals` - Get approval status
- POST `/api/v1/offers/{id}/generate-letter` - Generate PDF

### ✅ Dashboard (2 endpoints)
- GET `/api/v1/dashboard/pipeline` - Pipeline statistics
- GET `/api/v1/dashboard/metrics` - Recruitment metrics

### 🔄 Onboarding (Partial - 4 endpoints planned)
- POST `/api/v1/onboarding/tasks` - Create task
- POST `/api/v1/onboarding/documents` - Upload document
- POST `/api/v1/onboarding/verify` - Verify document
- GET `/api/v1/onboarding/{offer_id}/status` - Get status

### 🔄 Candidate Portal (Partial - 6 endpoints planned)
- GET `/api/v1/portal/applications` - My applications
- GET `/api/v1/portal/interviews` - My interviews
- GET `/api/v1/portal/offers` - My offers
- POST `/api/v1/portal/documents` - Upload documents
- GET `/api/v1/portal/messages` - Get messages
- POST `/api/v1/portal/messages` - Send message

### 🔄 Referrals (Partial - 4 endpoints planned)
- POST `/api/v1/referrals/` - Create referral
- GET `/api/v1/referrals/` - List referrals
- GET `/api/v1/referrals/{id}/status` - Get status
- POST `/api/v1/referrals/{id}/approve-bonus` - Approve bonus

### ⏳ Compliance & Audit (5 endpoints planned)
- GET `/api/v1/audit/logs` - Get audit logs
- GET `/api/v1/audit/access-logs` - Get access logs
- POST `/api/v1/gdpr/consent` - Record consent
- POST `/api/v1/gdpr/export-data` - Export user data
- DELETE `/api/v1/gdpr/delete-data` - Delete user data

## Key Features Implemented

### Authentication & Security
- ✅ JWT token-based authentication
- ✅ Password hashing with bcrypt
- ✅ Token refresh mechanism
- ✅ Role-based access control (RBAC) structure
- ✅ Current user dependency injection

### Business Logic
- ✅ Multi-level approval workflows (requisitions, offers)
- ✅ Duplicate detection (candidates, applications)
- ✅ Status management with validation
- ✅ Auto-generated numbers (requisition, application, offer)
- ✅ Cascade operations (delete candidate → delete documents)
- ✅ Aggregate calculations (interview feedback averages)

### Data Management
- ✅ Advanced filtering (search, skills, experience, location)
- ✅ Pagination (skip/limit)
- ✅ Sorting by date
- ✅ Status tracking across all entities
- ✅ Relationship management (panels, approvals, documents)

### AI Integration (Placeholders)
- 🔄 Resume parsing
- 🔄 Candidate-job matching score
- 🔄 Job description generation
- 🔄 Interview feedback summarization

### File Management
- ✅ Resume upload structure
- ✅ Document tracking
- 🔄 S3 integration (placeholder)
- 🔄 PDF generation (placeholder)

### Notifications (Planned)
- ⏳ Email notifications
- ⏳ SMS notifications
- ⏳ WhatsApp notifications
- ⏳ In-app notifications

## API Design Principles

1. **RESTful**: Standard HTTP methods (GET, POST, PUT, DELETE)
2. **Consistent**: Uniform response structure
3. **Validated**: Pydantic schema validation
4. **Secure**: Authentication required for most endpoints
5. **Documented**: OpenAPI/Swagger documentation
6. **Error Handling**: Proper HTTP status codes and error messages
7. **Filtering**: Query parameters for list endpoints
8. **Pagination**: Skip/limit for large datasets

## Next Steps

1. **Complete Remaining Endpoints**
   - Onboarding module
   - Candidate portal
   - Referrals
   - Compliance & audit

2. **Implement AI Features**
   - Resume parsing with Sentence Transformers
   - Candidate matching algorithm
   - JD generation with GPT-2

3. **Add Integrations**
   - AWS S3 for file storage
   - Email service (SMTP)
   - SMS/WhatsApp (Twilio)
   - Calendar (Google/Outlook)
   - Video conferencing (Zoom/Meet/Teams)

4. **Testing**
   - Unit tests for all endpoints
   - Integration tests
   - Load testing

5. **Documentation**
   - API usage examples
   - Postman collection
   - Integration guides

## Running the API

```bash
# Setup
cd backend
./setup.sh

# Run
source venv/bin/activate
python main.py
```

Access at: http://localhost:8000/api/v1/docs
