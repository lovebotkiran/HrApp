# AgenticHR - Recruitment Functionalities Reference

## Complete List of Recruitment Features

### 1. Job Requisition Management ✅

**Purpose**: Initiate hiring requests with proper approval workflows

**Features**:
- ✅ Create job requisitions with detailed requirements
- ✅ Multi-level approval workflow (Manager → HR → Director)
- ✅ Define job details (role, skills, experience, salary range, employment type)
- ✅ AI-powered job description generation (placeholder)
- ✅ Track requisition status (draft, pending, approved, rejected, closed)
- ✅ Priority levels (low, medium, high, urgent)
- ✅ Target hire date tracking
- ✅ Department-wise filtering

**API Endpoints**:
- `POST /api/v1/job-requisitions/` - Create requisition
- `GET /api/v1/job-requisitions/` - List all requisitions
- `GET /api/v1/job-requisitions/{id}` - Get requisition details
- `PUT /api/v1/job-requisitions/{id}` - Update requisition
- `DELETE /api/v1/job-requisitions/{id}` - Delete requisition
- `POST /api/v1/job-requisitions/{id}/approve` - Approve/reject
- `POST /api/v1/job-requisitions/{id}/generate-jd` - Generate JD

---

### 2. Job Posting 🔄

**Purpose**: Publish approved job requisitions across multiple platforms

**Features**:
- 🔄 Create job postings from approved requisitions
- 🔄 Publish to multiple platforms:
  - Company career page
  - LinkedIn (integration pending)
  - Other job boards (integration pending)
- 🔄 Auto-expiry management
- 🔄 Track views and application counts
- 🔄 Multi-platform posting via API
- 🔄 Job code generation
- 🔄 Active/inactive status management

**API Endpoints**:
- `POST /api/v1/job-postings/` - Create posting
- `GET /api/v1/job-postings/` - List active postings
- `GET /api/v1/job-postings/{id}` - Get posting details
- `PUT /api/v1/job-postings/{id}` - Update posting
- `POST /api/v1/job-postings/{id}/publish` - Publish to platforms

---

### 3. Candidate Application Collection 🔄

**Purpose**: Collect and manage candidate applications from various sources

**Features**:
- 🔄 Online application form
- 🔄 Resume upload (PDF, DOC, DOCX)
- ⏳ Auto-parsing resumes into structured data:
  - Name, email, phone
  - Skills and experience
  - Education details
  - Work history
- 🔄 Duplicate candidate detection
- 🔄 Source tracking:
  - LinkedIn
  - Employee referral
  - Direct email
  - Career page
  - Job boards
- 🔄 Cover letter submission
- 🔄 Application number generation

**API Endpoints**:
- `POST /api/v1/applications/` - Submit application
- `GET /api/v1/applications/` - List applications
- `GET /api/v1/applications/{id}` - Get application details
- `PUT /api/v1/applications/{id}/status` - Update status

---

### 4. Resume Parsing & Candidate Profiling ⏳

**Purpose**: Automatically extract and structure candidate information using AI

**Features**:
- ⏳ AI-based skill extraction
- ⏳ AI match score against job description (0-100)
- ⏳ Create comprehensive candidate profile:
  - Experience summary
  - Education history
  - Skills with proficiency levels
  - Achievements
  - Projects
  - Certifications
- ⏳ Resume data stored in JSONB format
- 🔄 Manual profile editing

**Technology**:
- Open-source models: Sentence Transformers
- Custom parsing algorithms

**API Endpoints**:
- `POST /api/v1/candidates/{id}/upload-resume` - Upload and parse
- `POST /api/v1/candidates/{id}/parse` - Re-parse resume
- `GET /api/v1/candidates/{id}/profile` - Get full profile

---

### 5. Shortlisting & Screening 🔄

**Purpose**: Filter and evaluate candidates efficiently

**Features**:
- ⏳ Automated AI shortlisting based on:
  - Skills match
  - Experience requirements
  - Education qualifications
  - Location preferences
- 🔄 HR manual shortlisting option
- 🔄 Screening questions (MCQ or text-based)
- 🔄 Knock-out criteria:
  - Minimum experience
  - Required location
  - Mandatory skills
  - Salary expectations
- 🔄 Pre-assessment tests:
  - Aptitude tests
  - Coding challenges
  - Domain-specific tests
- 🔄 Scoring and ranking

**API Endpoints**:
- `POST /api/v1/applications/{id}/shortlist` - Shortlist candidate
- `POST /api/v1/applications/{id}/screen` - Add screening questions
- `POST /api/v1/assessments/` - Create assessment
- `GET /api/v1/assessments/{id}/results` - Get results

---

### 6. Interview Scheduling 🔄

**Purpose**: Organize and manage interview rounds efficiently

**Features**:
- 🔄 Multi-round interview setup
- 🔄 Interviewer assignment (single or panel)
- ⏳ Calendar integration:
  - Google Calendar (optional)
  - Outlook Calendar (optional)
- 🔄 Automatic notifications:
  - Email to candidate
  - ⏳ SMS notification (optional)
  - ⏳ WhatsApp notification (optional)
- 🔄 Rescheduling option with reason tracking
- ⏳ Video interview link generation:
  - Zoom (optional)
  - Google Meet (optional)
  - Microsoft Teams (optional)
- 🔄 Interview types:
  - Phone
  - Video
  - In-person
  - Panel

**API Endpoints**:
- `POST /api/v1/interviews/` - Schedule interview
- `GET /api/v1/interviews/` - List interviews
- `PUT /api/v1/interviews/{id}` - Update interview
- `POST /api/v1/interviews/{id}/reschedule` - Reschedule
- `POST /api/v1/interviews/{id}/cancel` - Cancel interview

---

### 7. Interview Management ✅

**Purpose**: Collect and aggregate interview feedback

**Features**:
- ✅ Interview feedback form with ratings:
  - Technical skills (1-5)
  - Communication (1-5)
  - Problem-solving (1-5)
  - Cultural fit (1-5)
- ✅ Panel sharing feedback
- ✅ Auto-computed average rating
- ✅ Ability to add notes & files
- ⏳ AI-generated summary of candidate performance
- ✅ Recommendation levels:
  - Strong hire
  - Hire
  - Maybe
  - No hire
  - Strong no hire
- ✅ Strengths and weaknesses tracking

**API Endpoints**:
- `POST /api/v1/interviews/{id}/feedback` - Submit feedback
- `GET /api/v1/interviews/{id}/feedback` - Get all feedback
- `GET /api/v1/interviews/{id}/summary` - Get AI summary

---

### 8. Offer Management ✅

**Purpose**: Generate, approve, and track job offers

**Features**:
- ✅ Offer letter generation with variables:
  - Salary breakdown (base, bonus, benefits)
  - Joining date
  - Role and department
  - Reporting structure
  - Probation period
  - Notice period
- ✅ Approval chain (HR → Finance → Director)
- 🔄 Digital signature / e-signature:
  - Upload signature image
  - ⏳ Draw signature with mouse
- ✅ Offer acceptance tracking
- ✅ Offer revision option
- ✅ Expiry management & reminders
- ✅ Offer status tracking:
  - Draft
  - Pending approval
  - Approved
  - Sent
  - Accepted
  - Rejected
  - Expired
  - Withdrawn

**API Endpoints**:
- `POST /api/v1/offers/` - Create offer
- `GET /api/v1/offers/` - List offers
- `POST /api/v1/offers/{id}/approve` - Approve offer
- `POST /api/v1/offers/{id}/send` - Send to candidate
- `POST /api/v1/offers/{id}/accept` - Candidate acceptance
- `PUT /api/v1/offers/{id}/revise` - Revise offer

---

### 9. Pre-onboarding 🔄

**Purpose**: Prepare selected candidates for joining

**Features**:
- 🔄 Appointment letter generation
- 🔄 Document submission tracking:
  - ID proof (Aadhar, PAN, Passport)
  - Education certificates
  - Bank details
  - Previous employment documents
- ⏳ Background verification (via dummy API):
  - Employment verification
  - Education verification
  - Criminal record check
  - Credit check
- 🔄 Form uploads:
  - Employee data collection form
  - NDA (Non-Disclosure Agreement)
  - EPF (Employee Provident Fund)
  - ESIC (Employee State Insurance)
  - Bank account details
- 🔄 Task management with due dates
- 🔄 Document verification status

**API Endpoints**:
- `POST /api/v1/onboarding/tasks` - Create task
- `POST /api/v1/onboarding/documents` - Upload document
- `POST /api/v1/onboarding/verify` - Verify document
- `GET /api/v1/onboarding/{offer_id}/status` - Get status

---

### 10. Candidate Portal ✅

**Purpose**: Self-service portal for candidates

**Features**:
- ✅ Track application status in real-time
- 🔄 Upload additional documents
- 🔄 Download offer letter
- 🔄 Schedule/reschedule interviews
- ⏳ Chatbot support for queries
- 🔄 View interview feedback (if shared)
- 🔄 Accept/reject offers
- 🔄 Update profile information
- 🔄 Message center for communication

**Access**:
- Token-based authentication
- Email link access
- Mobile-friendly interface

---

### 11. Recruitment Pipeline Dashboard ✅

**Purpose**: Visualize and analyze recruitment metrics

**Features**:
- ✅ Visual pipeline stages:
  - Applied
  - Screening
  - Shortlisted
  - Interview
  - Selected
  - Offered
  - Onboarded
- ✅ Real-time statistics:
  - Total applications
  - Active jobs
  - Interviews scheduled
  - Offers sent
- ⏳ Reports:
  - Time to hire (average days)
  - Recruitment cost per hire
  - Offer acceptance ratio
  - Candidate conversion funnel
  - Source effectiveness
- ✅ Trend indicators (up/down percentages)
- 🔄 Filterable by:
  - Date range
  - Department
  - Job position
  - Source

**API Endpoints**:
- `GET /api/v1/dashboard/pipeline` - Get pipeline stats
- `GET /api/v1/dashboard/metrics` - Get overall metrics
- `GET /api/v1/dashboard/reports` - Generate reports

---

### 12. Referral Management 🔄

**Purpose**: Manage employee referrals and rewards

**Features**:
- 🔄 Employee referral entry
- 🔄 Automated tracking through stages
- 🔄 Reward tracking:
  - Milestone-based rewards
  - Application milestone
  - Interview milestone
  - Selection milestone
  - Joining milestone
- 🔄 Stage-wise referral updates
- 🔄 Referral code generation
- 🔄 Bonus approval workflow
- 🔄 Payment tracking

**API Endpoints**:
- `POST /api/v1/referrals/` - Create referral
- `GET /api/v1/referrals/` - List referrals
- `GET /api/v1/referrals/{id}/status` - Get status
- `POST /api/v1/referrals/{id}/approve-bonus` - Approve bonus

---

### 13. Compliance & Audit ✅

**Purpose**: Ensure data security and regulatory compliance

**Features**:
- ✅ Logs for every action:
  - User ID
  - Action type
  - Resource affected
  - Old and new values
  - IP address
  - Timestamp
- ✅ GDPR/data privacy compliance:
  - Consent management
  - Data retention policies
  - Right to be forgotten
  - Data export
- ✅ Role-based access control (RBAC):
  - 8 predefined roles
  - 40+ granular permissions
  - Custom role creation
- ✅ Secure resume/document storage
- ✅ Data access logs
- 🔄 Automated data deletion based on retention policies

**API Endpoints**:
- `GET /api/v1/audit/logs` - Get audit logs
- `GET /api/v1/audit/access-logs` - Get access logs
- `POST /api/v1/gdpr/consent` - Record consent
- `POST /api/v1/gdpr/export-data` - Export user data
- `DELETE /api/v1/gdpr/delete-data` - Delete user data

---

## AI Features Summary

### Implemented (Placeholders)
- ⏳ AI auto-generate JD
- ⏳ AI shortlisting
- ⏳ AI-powered candidate ranking
- ⏳ AI interview question generation
- ⏳ AI feedback summarization
- ⏳ AI-driven final recommendation

### Technology Stack
- **Open-source models**: Sentence Transformers, GPT-2
- **Custom algorithms**: Skill matching, experience scoring
- **Future enhancements**: Fine-tuned models on recruitment data

---

## Automated Email Workflows

### Notification Templates Created
1. ✅ Application received confirmation
2. ✅ Interview scheduled notification
3. ✅ Offer letter sent
4. ✅ Application rejected (polite)
5. ✅ Onboarding reminder
6. ✅ Referral status update

### Trigger Points
- Application submission
- Shortlisting
- Interview scheduling
- Interview rescheduling
- Offer generation
- Offer acceptance/rejection
- Onboarding task assignment
- Document verification

---

## Legend

- ✅ **Fully Implemented**: Database schema, API structure, and basic functionality ready
- 🔄 **Partially Implemented**: Structure created, needs completion
- ⏳ **Pending**: Planned but not yet implemented

---

## Quick Reference: Database Tables

| Module | Tables | Count |
|--------|--------|-------|
| User Management | users, roles, permissions, role_permissions, user_roles | 5 |
| Job Requisitions | job_requisitions, job_requisition_approvals | 2 |
| Job Postings | job_postings, job_posting_platforms | 2 |
| Candidates | candidates, candidate_documents, candidate_skills, candidate_education, candidate_experience | 5 |
| Applications | applications, screening_questions, candidate_assessments, assessment_results | 4 |
| Interviews | interviews, interview_panels, interview_feedback, interview_questions | 4 |
| Offers | offers, offer_approvals, offer_documents | 3 |
| Onboarding | onboarding_tasks, document_submissions, background_verifications | 3 |
| Candidate Portal | candidate_portal_access, candidate_messages | 2 |
| Referrals | referrals, referral_rewards | 2 |
| Analytics | recruitment_metrics, candidate_sources | 2 |
| Compliance | audit_logs, data_access_logs, gdpr_consent, data_retention_policies | 4 |
| Notifications | notification_templates, notification_queue | 2 |
| **Total** | | **40** |

---

## API Endpoint Summary

| Module | Endpoints | Status |
|--------|-----------|--------|
| Authentication | 5 | ✅ Complete |
| Job Requisitions | 7 | ✅ Complete |
| Job Postings | 5 | 🔄 Partial |
| Candidates | 4 | 🔄 Partial |
| Applications | 4 | 🔄 Partial |
| Interviews | 6 | 🔄 Partial |
| Offers | 5 | 🔄 Partial |
| Onboarding | 4 | ⏳ Pending |
| Candidate Portal | 6 | ⏳ Pending |
| Referrals | 4 | ⏳ Pending |
| Dashboard | 3 | ✅ Complete |
| Compliance | 5 | ⏳ Pending |
| **Total** | **58** | **~30% Complete** |

---

This reference guide provides a comprehensive overview of all recruitment functionalities in the AgenticHR system.
