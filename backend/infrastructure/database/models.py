from sqlalchemy import (
    Column, String, Boolean, Integer, DECIMAL, TIMESTAMP, Text, 
    Date, ForeignKey, ARRAY, JSON, CheckConstraint, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from datetime import datetime
from infrastructure.database.connection import Base


class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    department = Column(String(100), index=True)
    designation = Column(String(100))
    is_active = Column(Boolean, default=True, index=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    last_login = Column(TIMESTAMP)
    
    # Relationships
    roles = relationship("UserRole", back_populates="user")


class Role(Base):
    __tablename__ = "roles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(50), unique=True, nullable=False)
    description = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    permissions = relationship("RolePermission", back_populates="role")


class Permission(Base):
    __tablename__ = "permissions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), unique=True, nullable=False)
    resource = Column(String(50), nullable=False)
    action = Column(String(50), nullable=False)
    description = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())


class UserRole(Base):
    __tablename__ = "user_roles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id"), nullable=False)
    assigned_at = Column(TIMESTAMP, server_default=func.now())
    
    user = relationship("User", back_populates="roles")
    role = relationship("Role")


class RolePermission(Base):
    __tablename__ = "role_permissions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id"), nullable=False)
    permission_id = Column(UUID(as_uuid=True), ForeignKey("permissions.id"), nullable=False)
    
    role = relationship("Role", back_populates="permissions")
    permission = relationship("Permission")


class JobRequisition(Base):
    __tablename__ = "job_requisitions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    requisition_number = Column(String(50), unique=True, nullable=False)
    title = Column(String(200), nullable=False)
    department = Column(String(100), nullable=False)
    position_count = Column(Integer, default=1)
    employment_type = Column(String(50))
    experience_min = Column(Integer)
    experience_max = Column(Integer)
    salary_min = Column(DECIMAL(12, 2))
    salary_max = Column(DECIMAL(12, 2))
    currency = Column(String(10), default="INR")
    location = Column(String(100))
    required_skills = Column(ARRAY(String))
    preferred_skills = Column(ARRAY(String))
    education_requirements = Column(Text)
    job_description = Column(Text)
    responsibilities = Column(Text)
    benefits = Column(Text)
    status = Column(String(50), default="draft")
    priority = Column(String(50), default="medium")
    target_hire_date = Column(Date)
    reason_for_hiring = Column(Text)
    requested_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    job_postings = relationship("JobPosting", back_populates="requisition")
    approvals = relationship("JobRequisitionApproval", back_populates="requisition")


class JobRequisitionApproval(Base):
    __tablename__ = "job_requisition_approvals"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    requisition_id = Column(UUID(as_uuid=True), ForeignKey("job_requisitions.id"), nullable=False)
    approver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    level = Column(Integer, default=1)
    status = Column(String(50), default="pending")  # pending, approved, rejected
    comments = Column(Text)
    updated_at = Column(TIMESTAMP, server_default=func.now())
    
    requisition = relationship("JobRequisition", back_populates="approvals")
    approver = relationship("User")


class JobPosting(Base):
    __tablename__ = "job_postings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    job_code = Column(String(50), unique=True, nullable=False)
    requisition_id = Column(UUID(as_uuid=True), ForeignKey("job_requisitions.id"))
    title = Column(String(200), nullable=False)
    description = Column(Text)
    requirements = Column(Text)
    responsibilities = Column(Text)
    benefits = Column(Text)
    location = Column(String(100))
    employment_type = Column(String(50))
    experience_min = Column(Integer)
    experience_max = Column(Integer)
    salary_min = Column(DECIMAL(12, 2))
    salary_max = Column(DECIMAL(12, 2))
    currency = Column(String(10), default="INR")
    is_active = Column(Boolean, default=True)
    published_at = Column(TIMESTAMP)
    expires_at = Column(TIMESTAMP)
    status_state = Column(String(50), default="Draft", index=True)
    views_count = Column(Integer, default=0)
    applications_count = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    @property
    def status(self):
        # Override with manual status if it's set to a terminal state
        if self.status_state in ["Cancelled", "Rejected", "Expired"]:
            return self.status_state
            
        now = datetime.utcnow()
        if self.expires_at and self.expires_at < now:
            return "Expired"
        if not self.is_active:
            return "Draft"
        return "Active"
    
    # Relationships
    requisition = relationship("JobRequisition", back_populates="job_postings")
    applications = relationship("Application", back_populates="job_posting")
    platforms = relationship("JobPostingPlatform", back_populates="posting")


class JobPostingPlatform(Base):
    __tablename__ = "job_posting_platforms"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"), nullable=False)
    platform_name = Column(String(50), nullable=False)  # linkedin, indeed, monster, etc.
    platform_post_id = Column(String(100))
    post_url = Column(String(500))
    status = Column(String(50), default="active")  # active, expired, removed
    posted_at = Column(TIMESTAMP, server_default=func.now())
    expires_at = Column(TIMESTAMP)
    
    posting = relationship("JobPosting", back_populates="platforms")


class Candidate(Base):
    __tablename__ = "candidates"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20))
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    current_location = Column(String(100))
    preferred_location = Column(String(100))
    current_company = Column(String(200))
    current_designation = Column(String(200))
    total_experience_years = Column(DECIMAL(4, 1))
    current_ctc = Column(DECIMAL(12, 2))
    expected_ctc = Column(DECIMAL(12, 2))
    notice_period_days = Column(Integer)
    highest_education = Column(String(200))
    resume_url = Column(String(500))
    resume_parsed_data = Column(JSONB)
    skills = Column(ARRAY(Text))
    certifications = Column(ARRAY(Text))
    languages = Column(ARRAY(Text))
    is_blacklisted = Column(Boolean, default=False, index=True)
    is_active = Column(Boolean, default=True, index=True)
    blacklist_reason = Column(Text)
    linkedin_url = Column(String(500))
    portfolio_url = Column(String(500))
    skills = Column(ARRAY(String))
    certifications = Column(ARRAY(String))
    languages = Column(ARRAY(String))
    is_blacklisted = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    applications = relationship("Application", back_populates="candidate")
    documents = relationship("CandidateDocument", back_populates="candidate")


class CandidateDocument(Base):
    __tablename__ = "candidate_documents"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id"), nullable=False)
    document_type = Column(String(50), nullable=False)  # resume, cover_letter, certification, other
    file_name = Column(String(255), nullable=False)
    file_url = Column(String(500), nullable=False)
    uploaded_at = Column(TIMESTAMP, server_default=func.now())
    
    candidate = relationship("Candidate", back_populates="documents")


class Application(Base):
    __tablename__ = "applications"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_number = Column(String(50), unique=True, nullable=False)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"), nullable=False)
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id"), nullable=False)
    status = Column(String(50), default="applied")  # applied, screening, shortlisted, interview, offered, hired, rejected
    source = Column(String(50))  # linkedin, referral, website, agency, etc.
    cover_letter = Column(Text)
    ai_match_score = Column(DECIMAL(5, 2))
    ai_match_reasoning = Column(Text)
    applied_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    job_posting = relationship("JobPosting", back_populates="applications")
    candidate = relationship("Candidate", back_populates="applications")
    interviews = relationship("Interview", back_populates="application")
    offers = relationship("Offer", back_populates="application")


class Interview(Base):
    __tablename__ = "interviews"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_id = Column(UUID(as_uuid=True), ForeignKey("applications.id"), nullable=False)
    round_number = Column(Integer, default=1)
    round_name = Column(String(100))
    interview_type = Column(String(50))  # face_to_face, video, telephonic
    scheduled_date = Column(TIMESTAMP, nullable=False)
    duration_minutes = Column(Integer, default=60)
    location = Column(String(200))
    video_link = Column(String(500))
    status = Column(String(50), default="scheduled")  # scheduled, completed, cancelled, rescheduled, no_show
    reschedule_count = Column(Integer, default=0)
    feedback_submitted = Column(Boolean, default=False)
    overall_rating = Column(DECIMAL(3, 1))
    created_at = Column(TIMESTAMP, server_default=func.now())
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Relationships
    application = relationship("Application", back_populates="interviews")
    panel = relationship("InterviewPanel", back_populates="interview")
    feedback = relationship("InterviewFeedback", back_populates="interview")


class InterviewPanel(Base):
    __tablename__ = "interview_panel"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    interview_id = Column(UUID(as_uuid=True), ForeignKey("interviews.id"), nullable=False)
    interviewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    role = Column(String(50), default="interviewer")  # interviewer, observer, moderator
    
    interview = relationship("Interview", back_populates="panel")
    interviewer = relationship("User")


class InterviewFeedback(Base):
    __tablename__ = "interview_feedback"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    interview_id = Column(UUID(as_uuid=True), ForeignKey("interviews.id"), nullable=False)
    interviewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    technical_skills_rating = Column(Integer)
    communication_rating = Column(Integer)
    problem_solving_rating = Column(Integer)
    cultural_fit_rating = Column(Integer)
    strengths = Column(Text)
    weaknesses = Column(Text)
    comments = Column(Text)
    recommendation = Column(String(50))  # hire, reject, hold, next_round
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    interview = relationship("Interview", back_populates="feedback")
    interviewer = relationship("User")


class Offer(Base):
    __tablename__ = "offers"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    offer_number = Column(String(50), unique=True, nullable=False)
    application_id = Column(UUID(as_uuid=True), ForeignKey("applications.id"), nullable=False)
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id"), nullable=False)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"), nullable=False)
    designation = Column(String(100), nullable=False)
    department = Column(String(100))
    annual_ctc = Column(DECIMAL(12, 2), nullable=False)
    base_salary = Column(DECIMAL(12, 2), nullable=False)
    bonus = Column(DECIMAL(12, 2))
    benefits = Column(JSONB)
    joining_date = Column(Date, nullable=False)
    offer_valid_until = Column(Date, nullable=False)
    status = Column(String(50), default="draft")  # draft, approval_pending, approved, sent, accepted, rejected, withdrawn
    offer_letter_url = Column(String(500))
    employment_type = Column(String(50))
    location = Column(String(100))
    reporting_to = Column(String(100))
    probation_period_months = Column(Integer)
    notice_period_days = Column(Integer)
    created_at = Column(TIMESTAMP, server_default=func.now())
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    sent_at = Column(TIMESTAMP)
    accepted_at = Column(TIMESTAMP)
    
    # Relationships
    application = relationship("Application", back_populates="offers")
    approvals = relationship("OfferApproval", back_populates="offer")


class OfferApproval(Base):
    __tablename__ = "offer_approvals"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    offer_id = Column(UUID(as_uuid=True), ForeignKey("offers.id"), nullable=False)
    approver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    level = Column(Integer, default=1)
    status = Column(String(50), default="pending")  # pending, approved, rejected
    comments = Column(Text)
    updated_at = Column(TIMESTAMP, server_default=func.now())
    
    offer = relationship("Offer", back_populates="approvals")
    approver = relationship("User")


class OnboardingTask(Base):
    __tablename__ = "onboarding_tasks"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    offer_id = Column(UUID(as_uuid=True), ForeignKey("offers.id"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    category = Column(String(50))  # document, it_setup, training, introduction
    assigned_to = Column(UUID(as_uuid=True), ForeignKey("users.id"))  # Can be candidate (null) or HR/IT
    due_date = Column(Date)
    status = Column(String(50), default="pending")  # pending, in_progress, completed
    completed_at = Column(TIMESTAMP)
    document_url = Column(String(500))
    created_at = Column(TIMESTAMP, server_default=func.now())


class Referral(Base):
    __tablename__ = "referrals"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    referrer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    candidate_name = Column(String(200), nullable=False)
    candidate_email = Column(String(255), nullable=False)
    candidate_phone = Column(String(20))
    resume_url = Column(String(500))
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"))
    relationship = Column(String(100))
    status = Column(String(50), default="pending")  # pending, processed, hired, bonus_paid
    bonus_amount = Column(DECIMAL(10, 2))
    paid_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.now())


class Configuration(Base):
    __tablename__ = "configurations"
    
    key = Column(String(100), primary_key=True)
    value = Column(Text, nullable=True)
    description = Column(String(255))
    is_encrypted = Column(Boolean, default=False)
    category = Column(String(50))  # email, zoom, general
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class Employee(Base):
    __tablename__ = "employees"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True)
    employee_id = Column(String(50), unique=True, nullable=False)
    joining_date = Column(Date)
    department = Column(String(100))
    designation = Column(String(100))
    manager_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    employment_type = Column(String(50))
    employment_status = Column(String(50), default="active")
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    user = relationship("User", foreign_keys=[user_id])
    manager = relationship("User", foreign_keys=[manager_id])


class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    action = Column(String(100), nullable=False)
    resource_type = Column(String(50))
    resource_id = Column(String(100))
    details = Column(JSONB)
    ip_address = Column(String(50))
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    user = relationship("User")


class NotificationTemplate(Base):
    __tablename__ = "notification_templates"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    template_name = Column(String(100), unique=True, nullable=False)
    template_type = Column(String(50), nullable=False)  # email, sms, whatsapp
    subject = Column(String(200))
    body_template = Column(Text, nullable=False)
    variables = Column(JSONB)  # List of expected variables
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.now())


class InterviewQuestion(Base):
    __tablename__ = "interview_questions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_text = Column(Text, nullable=False)
    question_category = Column(String(100))  # technical, behavioral, situational
    difficulty_level = Column(String(50))  # easy, medium, hard
    round_type = Column(String(100))  # HR, Technical, Managerial
    expected_answer = Column(Text)
    ai_generated = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())


class DataRetentionPolicy(Base):
    __tablename__ = "data_retention_policies"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    data_type = Column(String(100), unique=True, nullable=False)
    retention_period_days = Column(Integer, nullable=False)
    auto_delete = Column(Boolean, default=True)
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User")
    candidate = relationship("Candidate")
