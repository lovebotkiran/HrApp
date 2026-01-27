-- AgenticHR - Comprehensive Seed Data
-- This script truncates all existing data and resets the database state.

-- 1. TRUNCATE ALL TABLES
TRUNCATE TABLE audit_logs CASCADE;
TRUNCATE TABLE onboarding_tasks CASCADE;
TRUNCATE TABLE referrals CASCADE;
TRUNCATE TABLE interview_feedback CASCADE;
TRUNCATE TABLE interview_panel CASCADE;
TRUNCATE TABLE interviews CASCADE;
TRUNCATE TABLE offers CASCADE;
TRUNCATE TABLE offer_approvals CASCADE;
TRUNCATE TABLE applications CASCADE;
TRUNCATE TABLE candidate_documents CASCADE;
TRUNCATE TABLE candidates CASCADE;
TRUNCATE TABLE job_posting_platforms CASCADE;
TRUNCATE TABLE job_postings CASCADE;
TRUNCATE TABLE job_requisition_approvals CASCADE;
TRUNCATE TABLE job_requisitions CASCADE;
TRUNCATE TABLE employees CASCADE;
TRUNCATE TABLE user_roles CASCADE;
TRUNCATE TABLE role_permissions CASCADE;
TRUNCATE TABLE permissions CASCADE;
TRUNCATE TABLE roles CASCADE;
TRUNCATE TABLE configurations CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE notification_templates CASCADE;
TRUNCATE TABLE interview_questions CASCADE;
TRUNCATE TABLE data_retention_policies CASCADE;
TRUNCATE TABLE candidate_sources CASCADE;

-- 2. SYSTEM CONFIGURATIONS
INSERT INTO configurations (key, value, description, category, is_encrypted) VALUES
    ('smtp_host', 'smtp.gmail.com', 'SMTP Host for emails', 'email', false),
    ('smtp_port', '587', 'SMTP Port for emails', 'email', false),
    ('smtp_user', 'kiran.adveccio@gmail.com', 'SMTP User email', 'email', false),
    ('smtp_password', 'mdtw xxie xnuo yzbj', 'SMTP App Password', 'email', true),
    ('smtp_from_email', 'kiran.adveccio@gmail.com', 'Sender email', 'email', false),
    ('smtp_from_name', 'AgenticHR', 'Sender name', 'email', false),
    ('zoom_account_id', 'eApapCraT066pxBTAKf1qA', 'Zoom Account ID', 'zoom', false),
    ('zoom_client_id', 'jAibQccwTpms9hDzAZt67Q', 'Zoom Client ID', 'zoom', false),
    ('zoom_client_secret', 'kkKsOR5xant1SduhQwfipkW9DEKxM81A', 'Zoom Client Secret', 'zoom', true);

-- 3. ROLES
INSERT INTO roles (id, name, description) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Super Admin', 'Full system access'),
    ('22222222-2222-2222-2222-222222222222', 'HR Manager', 'Manage recruitment process'),
    ('33333333-3333-3333-3333-333333333333', 'Recruiter', 'Handle candidate applications and interviews'),
    ('44444444-4444-4444-4444-444444444444', 'Hiring Manager', 'Raise requisitions and participate in interviews'),
    ('55555555-5555-5555-5555-555555555555', 'Interviewer', 'Conduct interviews and provide feedback'),
    ('88888888-8888-8888-8888-888888888888', 'Candidate', 'Access candidate portal');

-- 4. USERS
-- Admin: Admin@123 (bcrypt)
INSERT INTO users (id, email, password_hash, first_name, last_name, department, designation, is_active, is_verified) VALUES
    ('99999999-9999-9999-9999-999999999999', 'admin@agentichr.com', '$2b$12$TiGJiMQgcE1PGiHJqBy43edKDj/95O.Xdkg.9Lyu9NZsvSdx0mgiS', 'System', 'Administrator', 'IT', 'System Admin', TRUE, TRUE);

-- Recruiter 1: Password@123 (bcrypt)
INSERT INTO users (id, email, password_hash, first_name, last_name, department, designation, is_active, is_verified) VALUES
    ('77777777-1111-2222-3333-444444444444', 'kirankiruthigan@gmail.com', '$2b$12$jZFyZOvKoN/F8x85W5.DweAARpzCkyDyalXXzOJFsGvl9bMW.ityQ', 'Recruiter', 'One', 'HR', 'Senior Recruiter', TRUE, TRUE);

-- 5. USER ROLES
INSERT INTO user_roles (id, user_id, role_id) VALUES
    ('aaaaaaaa-1111-2222-3333-444444444444', '99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111'),
    ('bbbbbbbb-1111-2222-3333-444444444444', '77777777-1111-2222-3333-444444444444', '33333333-3333-3333-3333-333333333333');

-- 6. INITIAL JOB DATA
INSERT INTO job_requisitions (id, requisition_number, title, department, status, position_count, employment_type, currency, priority) VALUES
    ('11111111-aaaa-bbbb-cccc-dddddddddddd', 'REQ-2026-001', 'Software Engineer', 'Engineering', 'approved', 1, 'Full-time', 'INR', 'medium');

INSERT INTO job_postings (id, job_code, requisition_id, title, description, is_active, location, employment_type, currency, views_count, applications_count) VALUES
    ('22222222-aaaa-bbbb-cccc-dddddddddddd', 'JOB-SWE-001', '11111111-aaaa-bbbb-cccc-dddddddddddd', 'Software Engineer', 'We are looking for a rockstar dev.', TRUE, 'Remote', 'Full-time', 'INR', 0, 0);

-- 7. INITIAL CANDIDATE & APPLICATION
INSERT INTO candidates (id, email, first_name, last_name, phone) VALUES
    ('db5c2821-913f-43a0-b50a-f1fa7f1ffdea', 'stephankestroy@gmail.com', 'Stephan', 'Kestroy', '+91 98765 43210');

INSERT INTO applications (id, application_number, job_posting_id, candidate_id, status, source) VALUES
    ('ee4516d2-ca64-4692-a267-a05086b0c209', 'APP-2026-001', '22222222-aaaa-bbbb-cccc-dddddddddddd', 'db5c2821-913f-43a0-b50a-f1fa7f1ffdea', 'shortlisted', 'manual');

-- 8. CANDIDATE SOURCES
INSERT INTO candidate_sources (id, source_name, total_applications, total_hires) VALUES
    ('c0000001-1111-2222-3333-444444444444', 'LinkedIn', 0, 0),
    ('c0000002-1111-2222-3333-444444444444', 'Career Page', 0, 0),
    ('c0000003-1111-2222-3333-444444444444', 'Direct Email', 0, 0);
