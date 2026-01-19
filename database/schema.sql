-- AgenticHR - Recruitment Application Database Schema
-- PostgreSQL DDL Script

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USER MANAGEMENT
-- ============================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    department VARCHAR(100),
    designation VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

-- ============================================
-- JOB REQUISITION MANAGEMENT
-- ============================================

CREATE TABLE job_requisitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requisition_number VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    department VARCHAR(100) NOT NULL,
    requested_by UUID REFERENCES users(id),
    position_count INTEGER NOT NULL DEFAULT 1,
    employment_type VARCHAR(50) NOT NULL, -- Full-time, Part-time, Contract, Internship
    experience_min INTEGER,
    experience_max INTEGER,
    salary_min DECIMAL(12, 2),
    salary_max DECIMAL(12, 2),
    currency VARCHAR(10) DEFAULT 'INR',
    location VARCHAR(255),
    required_skills TEXT[],
    preferred_skills TEXT[],
    education_requirements TEXT,
    job_description TEXT,
    responsibilities TEXT,
    benefits TEXT,
    status VARCHAR(50) DEFAULT 'draft', -- draft, pending_approval, approved, rejected, closed
    priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high, urgent
    target_hire_date DATE,
    reason_for_hiring TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE job_requisition_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requisition_id UUID REFERENCES job_requisitions(id) ON DELETE CASCADE,
    approver_id UUID REFERENCES users(id),
    approval_level INTEGER NOT NULL, -- 1: Manager, 2: HR, 3: Director
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
    comments TEXT,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- JOB POSTING
-- ============================================

CREATE TABLE job_postings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requisition_id UUID REFERENCES job_requisitions(id),
    job_code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    requirements TEXT,
    responsibilities TEXT,
    benefits TEXT,
    location VARCHAR(255),
    employment_type VARCHAR(50),
    experience_min INTEGER,
    experience_max INTEGER,
    salary_min DECIMAL(12, 2),
    salary_max DECIMAL(12, 2),
    currency VARCHAR(10) DEFAULT 'INR',
    skills_required TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    published_at TIMESTAMP,
    expires_at TIMESTAMP,
    views_count INTEGER DEFAULT 0,
    applications_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE job_posting_platforms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_posting_id UUID REFERENCES job_postings(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL, -- career_page, linkedin, naukri, indeed, etc.
    external_id VARCHAR(255),
    posted_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending', -- pending, posted, failed, expired
    post_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- CANDIDATE MANAGEMENT
-- ============================================

CREATE TABLE candidates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    current_location VARCHAR(255),
    preferred_location VARCHAR(255),
    current_company VARCHAR(255),
    current_designation VARCHAR(255),
    total_experience_years DECIMAL(4, 2),
    current_ctc DECIMAL(12, 2),
    expected_ctc DECIMAL(12, 2),
    notice_period_days INTEGER,
    highest_education VARCHAR(100),
    linkedin_url TEXT,
    portfolio_url TEXT,
    resume_url TEXT,
    resume_parsed_data JSONB,
    skills TEXT[],
    certifications TEXT[],
    languages TEXT[],
    is_blacklisted BOOLEAN DEFAULT FALSE,
    blacklist_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_number VARCHAR(50) UNIQUE NOT NULL,
    job_posting_id UUID REFERENCES job_postings(id),
    candidate_id UUID REFERENCES candidates(id),
    source VARCHAR(50) NOT NULL, -- linkedin, referral, email, career_page, job_board
    referrer_id UUID REFERENCES users(id), -- If source is referral
    status VARCHAR(50) DEFAULT 'applied', -- applied, screening, shortlisted, interview, selected, offered, rejected, withdrawn
    ai_match_score DECIMAL(5, 2), -- 0-100
    ai_match_reasoning TEXT,
    cover_letter TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE candidate_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL, -- resume, cover_letter, certificate, id_proof, etc.
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE candidate_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    proficiency_level VARCHAR(50), -- beginner, intermediate, advanced, expert
    years_of_experience DECIMAL(4, 2),
    is_verified BOOLEAN DEFAULT FALSE,
    source VARCHAR(50) -- resume_parsed, self_reported, assessment
);

CREATE TABLE candidate_education (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    degree VARCHAR(100) NOT NULL,
    field_of_study VARCHAR(100),
    institution VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    start_date DATE,
    end_date DATE,
    grade VARCHAR(50),
    is_current BOOLEAN DEFAULT FALSE
);

CREATE TABLE candidate_experience (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    company_name VARCHAR(255) NOT NULL,
    designation VARCHAR(100) NOT NULL,
    location VARCHAR(255),
    start_date DATE,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    description TEXT,
    achievements TEXT[]
);

-- ============================================
-- SCREENING & SHORTLISTING
-- ============================================

CREATE TABLE screening_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_posting_id UUID REFERENCES job_postings(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL, -- mcq, text, boolean, numeric
    options JSONB, -- For MCQ questions
    correct_answer TEXT, -- For auto-grading
    is_knockout BOOLEAN DEFAULT FALSE,
    knockout_criteria TEXT,
    order_index INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE candidate_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    assessment_type VARCHAR(50) NOT NULL, -- screening, aptitude, coding, domain
    total_questions INTEGER,
    correct_answers INTEGER,
    score DECIMAL(5, 2),
    max_score DECIMAL(5, 2),
    percentage DECIMAL(5, 2),
    time_taken_minutes INTEGER,
    status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, expired
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assessment_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID REFERENCES candidate_assessments(id) ON DELETE CASCADE,
    question_id UUID REFERENCES screening_questions(id),
    candidate_answer TEXT,
    is_correct BOOLEAN,
    score DECIMAL(5, 2),
    answered_at TIMESTAMP
);

-- ============================================
-- INTERVIEW MANAGEMENT
-- ============================================

CREATE TABLE interviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    round_name VARCHAR(100), -- Technical, HR, Managerial, etc.
    interview_type VARCHAR(50) NOT NULL, -- phone, video, in_person, panel
    scheduled_date TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    location VARCHAR(255), -- For in-person interviews
    video_link TEXT, -- Zoom/Meet/Teams link
    status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, rescheduled, completed, cancelled, no_show
    reschedule_count INTEGER DEFAULT 0,
    reschedule_reason TEXT,
    meeting_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE interview_panels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interview_id UUID REFERENCES interviews(id) ON DELETE CASCADE,
    interviewer_id UUID REFERENCES users(id),
    role VARCHAR(50), -- primary, secondary, observer
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE interview_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interview_id UUID REFERENCES interviews(id) ON DELETE CASCADE,
    interviewer_id UUID REFERENCES users(id),
    technical_skills_rating INTEGER CHECK (technical_skills_rating BETWEEN 1 AND 5),
    communication_rating INTEGER CHECK (communication_rating BETWEEN 1 AND 5),
    problem_solving_rating INTEGER CHECK (problem_solving_rating BETWEEN 1 AND 5),
    cultural_fit_rating INTEGER CHECK (cultural_fit_rating BETWEEN 1 AND 5),
    overall_rating DECIMAL(3, 2),
    strengths TEXT,
    weaknesses TEXT,
    comments TEXT,
    recommendation VARCHAR(50), -- strong_hire, hire, maybe, no_hire, strong_no_hire
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE interview_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_posting_id UUID REFERENCES job_postings(id),
    round_type VARCHAR(50),
    question_text TEXT NOT NULL,
    question_category VARCHAR(100), -- technical, behavioral, situational
    difficulty_level VARCHAR(50), -- easy, medium, hard
    ai_generated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- OFFER MANAGEMENT
-- ============================================

CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_number VARCHAR(50) UNIQUE NOT NULL,
    application_id UUID REFERENCES applications(id),
    candidate_id UUID REFERENCES candidates(id),
    job_posting_id UUID REFERENCES job_postings(id),
    designation VARCHAR(255) NOT NULL,
    department VARCHAR(100),
    annual_ctc DECIMAL(12, 2) NOT NULL,
    base_salary DECIMAL(12, 2) NOT NULL,
    bonus DECIMAL(12, 2),
    benefits JSONB,
    joining_date DATE NOT NULL,
    offer_valid_until DATE NOT NULL,
    employment_type VARCHAR(50),
    location VARCHAR(255),
    reporting_to VARCHAR(255),
    probation_period_months INTEGER,
    notice_period_days INTEGER,
    offer_letter_url TEXT,
    status VARCHAR(50) DEFAULT 'draft', -- draft, pending_approval, approved, sent, accepted, rejected, expired, withdrawn
    sent_at TIMESTAMP,
    accepted_at TIMESTAMP,
    rejected_at TIMESTAMP,
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE offer_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID REFERENCES offers(id) ON DELETE CASCADE,
    approver_id UUID REFERENCES users(id),
    approval_level INTEGER NOT NULL, -- 1: HR, 2: Finance, 3: Director
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
    comments TEXT,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE offer_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID REFERENCES offers(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL, -- offer_letter, appointment_letter, nda, etc.
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    requires_signature BOOLEAN DEFAULT FALSE,
    signature_url TEXT,
    signed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- PRE-ONBOARDING
-- ============================================

CREATE TABLE onboarding_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID REFERENCES offers(id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    task_description TEXT,
    task_type VARCHAR(50), -- document_upload, form_fill, verification, training
    is_mandatory BOOLEAN DEFAULT TRUE,
    due_date DATE,
    status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, overdue
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE document_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID REFERENCES offers(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES candidates(id),
    document_type VARCHAR(100) NOT NULL, -- id_proof, address_proof, education, bank_details, etc.
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    verification_status VARCHAR(50) DEFAULT 'pending', -- pending, verified, rejected
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP,
    rejection_reason TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE background_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id),
    offer_id UUID REFERENCES offers(id),
    verification_type VARCHAR(50) NOT NULL, -- employment, education, criminal, credit
    status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, failed
    vendor_name VARCHAR(100),
    vendor_reference_id VARCHAR(100),
    result VARCHAR(50), -- clear, discrepancy, major_issue
    result_details JSONB,
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- ============================================
-- CANDIDATE PORTAL
-- ============================================

CREATE TABLE candidate_portal_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    access_token VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_accessed TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

CREATE TABLE candidate_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id),
    application_id UUID REFERENCES applications(id),
    sender_type VARCHAR(50) NOT NULL, -- candidate, recruiter, system
    sender_id UUID REFERENCES users(id),
    message_text TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- REFERRAL MANAGEMENT
-- ============================================

CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID REFERENCES users(id),
    candidate_id UUID REFERENCES candidates(id),
    job_posting_id UUID REFERENCES job_postings(id),
    application_id UUID REFERENCES applications(id),
    referral_code VARCHAR(50) UNIQUE,
    status VARCHAR(50) DEFAULT 'submitted', -- submitted, screening, interview, hired, rejected
    referral_bonus_amount DECIMAL(10, 2),
    bonus_status VARCHAR(50) DEFAULT 'pending', -- pending, approved, paid
    bonus_paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE referral_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referral_id UUID REFERENCES referrals(id) ON DELETE CASCADE,
    milestone VARCHAR(50) NOT NULL, -- application, interview, selection, joining
    reward_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, paid
    approved_by UUID REFERENCES users(id),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ANALYTICS & REPORTING
-- ============================================

CREATE TABLE recruitment_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_posting_id UUID REFERENCES job_postings(id),
    metric_date DATE NOT NULL,
    applications_received INTEGER DEFAULT 0,
    candidates_screened INTEGER DEFAULT 0,
    candidates_shortlisted INTEGER DEFAULT 0,
    interviews_scheduled INTEGER DEFAULT 0,
    interviews_completed INTEGER DEFAULT 0,
    offers_made INTEGER DEFAULT 0,
    offers_accepted INTEGER DEFAULT 0,
    offers_rejected INTEGER DEFAULT 0,
    average_time_to_hire_days DECIMAL(5, 2),
    average_cost_per_hire DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE candidate_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) NOT NULL,
    total_applications INTEGER DEFAULT 0,
    total_hires INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5, 2),
    average_quality_score DECIMAL(5, 2),
    total_cost DECIMAL(10, 2),
    cost_per_hire DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- COMPLIANCE & AUDIT
-- ============================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE data_access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    accessed_resource VARCHAR(100) NOT NULL,
    resource_id UUID,
    access_type VARCHAR(50), -- view, download, export
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gdpr_consent (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    consent_type VARCHAR(50) NOT NULL, -- data_processing, marketing, third_party_sharing
    is_granted BOOLEAN DEFAULT FALSE,
    granted_at TIMESTAMP,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE data_retention_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data_type VARCHAR(100) NOT NULL,
    retention_period_days INTEGER NOT NULL,
    auto_delete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(100) UNIQUE NOT NULL,
    template_type VARCHAR(50) NOT NULL, -- email, sms, whatsapp, in_app
    subject VARCHAR(255),
    body_template TEXT NOT NULL,
    variables JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notification_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_type VARCHAR(50) NOT NULL, -- candidate, user
    recipient_id UUID NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- email, sms, whatsapp, in_app
    template_id UUID REFERENCES notification_templates(id),
    subject VARCHAR(255),
    body TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, sent, failed, cancelled
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_department ON users(department);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Job Requisitions
CREATE INDEX idx_job_requisitions_status ON job_requisitions(status);
CREATE INDEX idx_job_requisitions_department ON job_requisitions(department);
CREATE INDEX idx_job_requisitions_requested_by ON job_requisitions(requested_by);

-- Job Postings
CREATE INDEX idx_job_postings_is_active ON job_postings(is_active);
CREATE INDEX idx_job_postings_expires_at ON job_postings(expires_at);
CREATE INDEX idx_job_postings_requisition_id ON job_postings(requisition_id);

-- Candidates
CREATE INDEX idx_candidates_email ON candidates(email);
CREATE INDEX idx_candidates_skills ON candidates USING GIN(skills);
CREATE INDEX idx_candidates_is_blacklisted ON candidates(is_blacklisted);

-- Applications
CREATE INDEX idx_applications_job_posting_id ON applications(job_posting_id);
CREATE INDEX idx_applications_candidate_id ON applications(candidate_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_source ON applications(source);
CREATE INDEX idx_applications_applied_at ON applications(applied_at);

-- Interviews
CREATE INDEX idx_interviews_application_id ON interviews(application_id);
CREATE INDEX idx_interviews_scheduled_date ON interviews(scheduled_date);
CREATE INDEX idx_interviews_status ON interviews(status);

-- Offers
CREATE INDEX idx_offers_application_id ON offers(application_id);
CREATE INDEX idx_offers_candidate_id ON offers(candidate_id);
CREATE INDEX idx_offers_status ON offers(status);
CREATE INDEX idx_offers_joining_date ON offers(joining_date);

-- Audit Logs
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Notifications
CREATE INDEX idx_notification_queue_status ON notification_queue(status);
CREATE INDEX idx_notification_queue_scheduled_at ON notification_queue(scheduled_at);
CREATE INDEX idx_notification_queue_recipient ON notification_queue(recipient_type, recipient_id);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_requisitions_updated_at BEFORE UPDATE ON job_requisitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_postings_updated_at BEFORE UPDATE ON job_postings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_candidates_updated_at BEFORE UPDATE ON candidates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_interviews_updated_at BEFORE UPDATE ON interviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_referrals_updated_at BEFORE UPDATE ON referrals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
