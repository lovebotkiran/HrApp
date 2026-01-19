-- AgenticHR - Seed Data for Initial Setup

-- ============================================
-- DEFAULT ROLES
-- ============================================

INSERT INTO roles (id, name, description) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Super Admin', 'Full system access'),
    ('22222222-2222-2222-2222-222222222222', 'HR Manager', 'Manage recruitment process'),
    ('33333333-3333-3333-3333-333333333333', 'Recruiter', 'Handle candidate applications and interviews'),
    ('44444444-4444-4444-4444-444444444444', 'Hiring Manager', 'Raise requisitions and participate in interviews'),
    ('55555555-5555-5555-5555-555555555555', 'Interviewer', 'Conduct interviews and provide feedback'),
    ('66666666-6666-6666-6666-666666666666', 'Director', 'Approve requisitions and offers'),
    ('77777777-7777-7777-7777-777777777777', 'Finance', 'Approve offer compensation'),
    ('88888888-8888-8888-8888-888888888888', 'Candidate', 'Access candidate portal');

-- ============================================
-- PERMISSIONS
-- ============================================

INSERT INTO permissions (name, resource, action, description) VALUES
    -- Job Requisitions
    ('create_job_requisition', 'job_requisition', 'create', 'Create new job requisition'),
    ('view_job_requisition', 'job_requisition', 'read', 'View job requisitions'),
    ('update_job_requisition', 'job_requisition', 'update', 'Update job requisitions'),
    ('delete_job_requisition', 'job_requisition', 'delete', 'Delete job requisitions'),
    ('approve_job_requisition', 'job_requisition', 'approve', 'Approve job requisitions'),
    
    -- Job Postings
    ('create_job_posting', 'job_posting', 'create', 'Create job postings'),
    ('view_job_posting', 'job_posting', 'read', 'View job postings'),
    ('update_job_posting', 'job_posting', 'update', 'Update job postings'),
    ('delete_job_posting', 'job_posting', 'delete', 'Delete job postings'),
    ('publish_job_posting', 'job_posting', 'publish', 'Publish job postings'),
    
    -- Candidates
    ('create_candidate', 'candidate', 'create', 'Create candidate profiles'),
    ('view_candidate', 'candidate', 'read', 'View candidate profiles'),
    ('update_candidate', 'candidate', 'update', 'Update candidate profiles'),
    ('delete_candidate', 'candidate', 'delete', 'Delete candidate profiles'),
    ('blacklist_candidate', 'candidate', 'blacklist', 'Blacklist candidates'),
    
    -- Applications
    ('view_application', 'application', 'read', 'View applications'),
    ('update_application_status', 'application', 'update', 'Update application status'),
    ('shortlist_candidate', 'application', 'shortlist', 'Shortlist candidates'),
    
    -- Interviews
    ('schedule_interview', 'interview', 'create', 'Schedule interviews'),
    ('view_interview', 'interview', 'read', 'View interviews'),
    ('update_interview', 'interview', 'update', 'Update interview details'),
    ('cancel_interview', 'interview', 'delete', 'Cancel interviews'),
    ('submit_feedback', 'interview', 'feedback', 'Submit interview feedback'),
    
    -- Offers
    ('create_offer', 'offer', 'create', 'Create job offers'),
    ('view_offer', 'offer', 'read', 'View offers'),
    ('update_offer', 'offer', 'update', 'Update offers'),
    ('approve_offer', 'offer', 'approve', 'Approve offers'),
    ('send_offer', 'offer', 'send', 'Send offers to candidates'),
    
    -- Onboarding
    ('view_onboarding', 'onboarding', 'read', 'View onboarding tasks'),
    ('manage_onboarding', 'onboarding', 'manage', 'Manage onboarding process'),
    
    -- Referrals
    ('create_referral', 'referral', 'create', 'Create referrals'),
    ('view_referral', 'referral', 'read', 'View referrals'),
    ('approve_referral_bonus', 'referral', 'approve', 'Approve referral bonuses'),
    
    -- Analytics
    ('view_analytics', 'analytics', 'read', 'View recruitment analytics'),
    ('export_reports', 'analytics', 'export', 'Export reports'),
    
    -- Admin
    ('manage_users', 'user', 'manage', 'Manage users'),
    ('manage_roles', 'role', 'manage', 'Manage roles and permissions'),
    ('view_audit_logs', 'audit', 'read', 'View audit logs');

-- ============================================
-- ROLE-PERMISSION MAPPINGS
-- ============================================

-- Super Admin - All permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT '11111111-1111-1111-1111-111111111111', id FROM permissions;

-- HR Manager
INSERT INTO role_permissions (role_id, permission_id)
SELECT '22222222-2222-2222-2222-222222222222', id FROM permissions
WHERE name IN (
    'create_job_requisition', 'view_job_requisition', 'update_job_requisition', 'approve_job_requisition',
    'create_job_posting', 'view_job_posting', 'update_job_posting', 'publish_job_posting',
    'create_candidate', 'view_candidate', 'update_candidate', 'blacklist_candidate',
    'view_application', 'update_application_status', 'shortlist_candidate',
    'schedule_interview', 'view_interview', 'update_interview', 'cancel_interview',
    'create_offer', 'view_offer', 'update_offer', 'send_offer',
    'view_onboarding', 'manage_onboarding',
    'view_referral', 'approve_referral_bonus',
    'view_analytics', 'export_reports'
);

-- Recruiter
INSERT INTO role_permissions (role_id, permission_id)
SELECT '33333333-3333-3333-3333-333333333333', id FROM permissions
WHERE name IN (
    'view_job_requisition', 'view_job_posting', 'update_job_posting',
    'create_candidate', 'view_candidate', 'update_candidate',
    'view_application', 'update_application_status', 'shortlist_candidate',
    'schedule_interview', 'view_interview', 'update_interview',
    'view_offer', 'view_onboarding', 'view_referral', 'view_analytics'
);

-- Hiring Manager
INSERT INTO role_permissions (role_id, permission_id)
SELECT '44444444-4444-4444-4444-444444444444', id FROM permissions
WHERE name IN (
    'create_job_requisition', 'view_job_requisition', 'update_job_requisition',
    'view_job_posting', 'view_candidate', 'view_application',
    'schedule_interview', 'view_interview', 'submit_feedback',
    'view_offer', 'view_analytics'
);

-- Interviewer
INSERT INTO role_permissions (role_id, permission_id)
SELECT '55555555-5555-5555-5555-555555555555', id FROM permissions
WHERE name IN (
    'view_candidate', 'view_application', 'view_interview', 'submit_feedback'
);

-- Director
INSERT INTO role_permissions (role_id, permission_id)
SELECT '66666666-6666-6666-6666-666666666666', id FROM permissions
WHERE name IN (
    'view_job_requisition', 'approve_job_requisition',
    'view_job_posting', 'view_candidate', 'view_application',
    'view_interview', 'view_offer', 'approve_offer',
    'view_analytics', 'export_reports'
);

-- Finance
INSERT INTO role_permissions (role_id, permission_id)
SELECT '77777777-7777-7777-7777-777777777777', id FROM permissions
WHERE name IN (
    'view_offer', 'approve_offer', 'view_analytics'
);

-- ============================================
-- DEFAULT ADMIN USER
-- ============================================

-- Password: Admin@123 (hashed with bcrypt)
INSERT INTO users (id, email, password_hash, first_name, last_name, department, designation, is_active, is_verified)
VALUES (
    '99999999-9999-9999-9999-999999999999',
    'admin@agentichr.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxF3z3H2i',
    'System',
    'Administrator',
    'IT',
    'System Admin',
    TRUE,
    TRUE
);

-- Assign Super Admin role
INSERT INTO user_roles (user_id, role_id)
VALUES ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111');

-- ============================================
-- NOTIFICATION TEMPLATES
-- ============================================

INSERT INTO notification_templates (template_name, template_type, subject, body_template, variables) VALUES
    ('application_received', 'email', 'Application Received - {{job_title}}', 
     'Dear {{candidate_name}},\n\nThank you for applying for the position of {{job_title}}. We have received your application and our team will review it shortly.\n\nApplication Number: {{application_number}}\n\nYou can track your application status at: {{portal_link}}\n\nBest regards,\nAgenticHR Team',
     '{"candidate_name": "string", "job_title": "string", "application_number": "string", "portal_link": "string"}'),
    
    ('interview_scheduled', 'email', 'Interview Scheduled - {{job_title}}',
     'Dear {{candidate_name}},\n\nCongratulations! You have been shortlisted for an interview.\n\nDetails:\nPosition: {{job_title}}\nRound: {{round_name}}\nDate & Time: {{interview_date}}\nDuration: {{duration}} minutes\nType: {{interview_type}}\n{{meeting_link}}\n\nPlease confirm your availability.\n\nBest regards,\nAgenticHR Team',
     '{"candidate_name": "string", "job_title": "string", "round_name": "string", "interview_date": "string", "duration": "number", "interview_type": "string", "meeting_link": "string"}'),
    
    ('offer_letter', 'email', 'Job Offer - {{designation}}',
     'Dear {{candidate_name}},\n\nWe are pleased to offer you the position of {{designation}} at our organization.\n\nPlease find the offer letter attached. Kindly review and accept the offer by {{offer_expiry_date}}.\n\nYou can access your offer letter at: {{offer_link}}\n\nWelcome to the team!\n\nBest regards,\nAgenticHR Team',
     '{"candidate_name": "string", "designation": "string", "offer_expiry_date": "string", "offer_link": "string"}'),
    
    ('application_rejected', 'email', 'Application Status - {{job_title}}',
     'Dear {{candidate_name}},\n\nThank you for your interest in the {{job_title}} position. After careful consideration, we have decided to move forward with other candidates whose qualifications more closely match our current needs.\n\nWe appreciate the time you invested in the application process and encourage you to apply for future openings that match your skills and experience.\n\nBest regards,\nAgenticHR Team',
     '{"candidate_name": "string", "job_title": "string"}'),
    
    ('onboarding_reminder', 'email', 'Onboarding Tasks Pending',
     'Dear {{candidate_name}},\n\nWelcome aboard! We are excited to have you join us on {{joining_date}}.\n\nPlease complete the following pending tasks:\n{{pending_tasks}}\n\nAccess your onboarding portal: {{portal_link}}\n\nBest regards,\nAgenticHR Team',
     '{"candidate_name": "string", "joining_date": "string", "pending_tasks": "string", "portal_link": "string"}'),
    
    ('referral_status_update', 'email', 'Referral Status Update',
     'Dear {{referrer_name}},\n\nYour referral {{candidate_name}} for the position of {{job_title}} has been updated.\n\nCurrent Status: {{status}}\n\n{{additional_message}}\n\nBest regards,\nAgenticHR Team',
     '{"referrer_name": "string", "candidate_name": "string", "job_title": "string", "status": "string", "additional_message": "string"}');

-- ============================================
-- SAMPLE INTERVIEW QUESTIONS (AI-Generated Templates)
-- ============================================

INSERT INTO interview_questions (question_text, question_category, difficulty_level, round_type, ai_generated) VALUES
    ('Tell me about yourself and your professional background.', 'behavioral', 'easy', 'HR', false),
    ('Why do you want to work for our company?', 'behavioral', 'easy', 'HR', false),
    ('What are your salary expectations?', 'behavioral', 'medium', 'HR', false),
    ('Describe a challenging project you worked on and how you handled it.', 'behavioral', 'medium', 'Technical', false),
    ('How do you handle conflicts in a team?', 'behavioral', 'medium', 'Managerial', false),
    ('What are your strengths and weaknesses?', 'behavioral', 'easy', 'HR', false),
    ('Where do you see yourself in 5 years?', 'behavioral', 'easy', 'HR', false),
    ('Explain a situation where you had to learn a new technology quickly.', 'situational', 'medium', 'Technical', false),
    ('How do you prioritize tasks when you have multiple deadlines?', 'situational', 'medium', 'Managerial', false),
    ('Describe your ideal work environment.', 'behavioral', 'easy', 'HR', false);

-- ============================================
-- DATA RETENTION POLICIES
-- ============================================

INSERT INTO data_retention_policies (data_type, retention_period_days, auto_delete) VALUES
    ('rejected_applications', 180, true),
    ('candidate_resumes', 730, false),
    ('interview_recordings', 365, true),
    ('audit_logs', 2555, false), -- 7 years
    ('expired_job_postings', 365, false);

-- ============================================
-- CANDIDATE SOURCES
-- ============================================

INSERT INTO candidate_sources (source_name, total_applications, total_hires, conversion_rate) VALUES
    ('LinkedIn', 0, 0, 0.00),
    ('Career Page', 0, 0, 0.00),
    ('Employee Referral', 0, 0, 0.00),
    ('Job Boards', 0, 0, 0.00),
    ('Campus Recruitment', 0, 0, 0.00),
    ('Recruitment Agency', 0, 0, 0.00),
    ('Direct Email', 0, 0, 0.00),
    ('Social Media', 0, 0, 0.00);
