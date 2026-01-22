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


class RolePermission(Base):
    __tablename__ = "role_permissions"
    
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True)
    permission_id = Column(UUID(as_uuid=True), ForeignKey("permissions.id", ondelete="CASCADE"), primary_key=True)
    
    # Relationships
    role = relationship("Role", back_populates="permissions")
    permission = relationship("Permission")


class UserRole(Base):
    __tablename__ = "user_roles"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True)
    assigned_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="roles")
    role = relationship("Role")


class JobRequisition(Base):
    __tablename__ = "job_requisitions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    requisition_number = Column(String(50), unique=True, nullable=False)
    title = Column(String(255), nullable=False)
    department = Column(String(100), nullable=False, index=True)
    requested_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    position_count = Column(Integer, nullable=False, default=1)
    employment_type = Column(String(50), nullable=False)
    experience_min = Column(Integer)
    experience_max = Column(Integer)
    salary_min = Column(DECIMAL(12, 2))
    salary_max = Column(DECIMAL(12, 2))
    currency = Column(String(10), default="INR")
    location = Column(String(255))
    required_skills = Column(ARRAY(Text))
    preferred_skills = Column(ARRAY(Text))
    education_requirements = Column(Text)
    job_description = Column(Text)
    responsibilities = Column(Text)
    benefits = Column(Text)
    status = Column(String(50), default="draft", index=True)
    priority = Column(String(20), default="medium")
    target_hire_date = Column(Date)
    reason_for_hiring = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    approvals = relationship("JobRequisitionApproval", back_populates="requisition")
    postings = relationship("JobPosting", back_populates="requisition")


class JobRequisitionApproval(Base):
    __tablename__ = "job_requisition_approvals"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    requisition_id = Column(UUID(as_uuid=True), ForeignKey("job_requisitions.id", ondelete="CASCADE"))
    approver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    approval_level = Column(Integer, nullable=False)
    status = Column(String(50), default="pending")
    comments = Column(Text)
    approved_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    requisition = relationship("JobRequisition", back_populates="approvals")


class JobPosting(Base):
    __tablename__ = "job_postings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    requisition_id = Column(UUID(as_uuid=True), ForeignKey("job_requisitions.id"))
    job_code = Column(String(50), unique=True, nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    requirements = Column(Text)
    responsibilities = Column(Text)
    benefits = Column(Text)
    location = Column(String(255))
    employment_type = Column(String(50))
    experience_min = Column(Integer)
    experience_max = Column(Integer)
    salary_min = Column(DECIMAL(12, 2))
    salary_max = Column(DECIMAL(12, 2))
    currency = Column(String(10), default="INR")
    skills_required = Column(ARRAY(Text))
    is_active = Column(Boolean, default=True, index=True)
    published_at = Column(TIMESTAMP)
    expires_at = Column(TIMESTAMP, index=True)
    status_state = Column(String(50), default="Draft", index=True)
    views_count = Column(Integer, default=0)
    applications_count = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
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
    requisition = relationship("JobRequisition", back_populates="postings")
    applications = relationship("Application", back_populates="job_posting")
    platforms = relationship("JobPostingPlatform", back_populates="job_posting")


class JobPostingPlatform(Base):
    __tablename__ = "job_posting_platforms"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id", ondelete="CASCADE"))
    platform = Column(String(50), nullable=False)
    external_id = Column(String(255))
    posted_at = Column(TIMESTAMP)
    status = Column(String(50), default="pending")
    post_url = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    job_posting = relationship("JobPosting", back_populates="platforms")


class Candidate(Base):
    __tablename__ = "candidates"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20))
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    current_location = Column(String(255))
    preferred_location = Column(String(255))
    current_company = Column(String(255))
    current_designation = Column(String(255))
    total_experience_years = Column(DECIMAL(4, 2))
    current_ctc = Column(DECIMAL(12, 2))
    expected_ctc = Column(DECIMAL(12, 2))
    notice_period_days = Column(Integer)
    highest_education = Column(String(100))
    linkedin_url = Column(Text)
    portfolio_url = Column(Text)
    resume_url = Column(Text)
    resume_parsed_data = Column(JSONB)
    skills = Column(ARRAY(Text))
    certifications = Column(ARRAY(Text))
    languages = Column(ARRAY(Text))
    is_blacklisted = Column(Boolean, default=False, index=True)
    blacklist_reason = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    applications = relationship("Application", back_populates="candidate")
    documents = relationship("CandidateDocument", back_populates="candidate")


class Application(Base):
    __tablename__ = "applications"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_number = Column(String(50), unique=True, nullable=False)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"), index=True)
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id"), index=True)
    source = Column(String(50), nullable=False, index=True)
    referrer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    status = Column(String(50), default="applied", index=True)
    ai_match_score = Column(DECIMAL(5, 2))
    ai_match_reasoning = Column(Text)
    cover_letter = Column(Text)
    applied_at = Column(TIMESTAMP, server_default=func.now(), index=True)
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    job_posting = relationship("JobPosting", back_populates="applications")
    candidate = relationship("Candidate", back_populates="applications")
    interviews = relationship("Interview", back_populates="application")

    @property
    def candidate_name(self):
        if self.candidate:
            return f"{self.candidate.first_name} {self.candidate.last_name}"
        return "Unknown"

    @property
    def job_title(self):
        if self.job_posting:
            return self.job_posting.title
        return "Unknown Position"


class CandidateDocument(Base):
    __tablename__ = "candidate_documents"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id", ondelete="CASCADE"))
    document_type = Column(String(50), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_url = Column(Text, nullable=False)
    file_size = Column(Integer)
    mime_type = Column(String(100))
    uploaded_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    candidate = relationship("Candidate", back_populates="documents")


class Interview(Base):
    __tablename__ = "interviews"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_id = Column(UUID(as_uuid=True), ForeignKey("applications.id", ondelete="CASCADE"), index=True)
    round_number = Column(Integer, nullable=False)
    round_name = Column(String(100))
    interview_type = Column(String(50), nullable=False)
    scheduled_date = Column(TIMESTAMP, nullable=False, index=True)
    duration_minutes = Column(Integer, default=60)
    location = Column(String(255))
    video_link = Column(Text)
    status = Column(String(50), default="scheduled", index=True)
    reschedule_count = Column(Integer, default=0)
    reschedule_reason = Column(Text)
    meeting_notes = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    application = relationship("Application", back_populates="interviews")
    feedback = relationship("InterviewFeedback", back_populates="interview")
    panels = relationship("InterviewPanel", back_populates="interview")


class InterviewPanel(Base):
    __tablename__ = "interview_panels"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    interview_id = Column(UUID(as_uuid=True), ForeignKey("interviews.id", ondelete="CASCADE"))
    interviewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    role = Column(String(50))
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    interview = relationship("Interview", back_populates="panels")


class InterviewFeedback(Base):
    __tablename__ = "interview_feedback"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    interview_id = Column(UUID(as_uuid=True), ForeignKey("interviews.id", ondelete="CASCADE"))
    interviewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    technical_skills_rating = Column(Integer, CheckConstraint('technical_skills_rating BETWEEN 1 AND 5'))
    communication_rating = Column(Integer, CheckConstraint('communication_rating BETWEEN 1 AND 5'))
    problem_solving_rating = Column(Integer, CheckConstraint('problem_solving_rating BETWEEN 1 AND 5'))
    cultural_fit_rating = Column(Integer, CheckConstraint('cultural_fit_rating BETWEEN 1 AND 5'))
    overall_rating = Column(DECIMAL(3, 2))
    strengths = Column(Text)
    weaknesses = Column(Text)
    comments = Column(Text)
    recommendation = Column(String(50))
    submitted_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    interview = relationship("Interview", back_populates="feedback")


class Offer(Base):
    __tablename__ = "offers"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    offer_number = Column(String(50), unique=True, nullable=False)
    application_id = Column(UUID(as_uuid=True), ForeignKey("applications.id"), index=True)
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id"), index=True)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"))
    designation = Column(String(255), nullable=False)
    department = Column(String(100))
    annual_ctc = Column(DECIMAL(12, 2), nullable=False)
    base_salary = Column(DECIMAL(12, 2), nullable=False)
    bonus = Column(DECIMAL(12, 2))
    benefits = Column(JSONB)
    joining_date = Column(Date, nullable=False, index=True)
    offer_valid_until = Column(Date, nullable=False)
    employment_type = Column(String(50))
    location = Column(String(255))
    reporting_to = Column(String(255))
    probation_period_months = Column(Integer)
    notice_period_days = Column(Integer)
    offer_letter_url = Column(Text)
    status = Column(String(50), default="draft", index=True)
    sent_at = Column(TIMESTAMP)
    accepted_at = Column(TIMESTAMP)
    rejected_at = Column(TIMESTAMP)
    rejection_reason = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    approvals = relationship("OfferApproval", back_populates="offer")


class OfferApproval(Base):
    __tablename__ = "offer_approvals"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    offer_id = Column(UUID(as_uuid=True), ForeignKey("offers.id", ondelete="CASCADE"))
    approver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    approval_level = Column(Integer, nullable=False)
    status = Column(String(50), default="pending")
    comments = Column(Text)
    approved_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    offer = relationship("Offer", back_populates="approvals")


class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    action = Column(String(100), nullable=False)
    resource_type = Column(String(50), nullable=False, index=True)
    resource_id = Column(UUID(as_uuid=True))
    old_values = Column(JSONB)
    new_values = Column(JSONB)
    ip_address = Column(String(45))
    user_agent = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now(), index=True)


class CandidateOCRText(Base):
    __tablename__ = "candidate_ocr_text"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_id = Column(UUID(as_uuid=True), ForeignKey("applications.id", ondelete="CASCADE"), index=True)
    raw_text = Column(Text)
    parsed_json = Column(JSONB)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    application = relationship("Application")


class CandidateEmbeddings(Base):
    __tablename__ = "candidate_embeddings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_id = Column(UUID(as_uuid=True), ForeignKey("applications.id", ondelete="CASCADE"), index=True)
    # Using ARRAY(DECIMAL) to store vectors.
    embedding_vector = Column(ARRAY(DECIMAL)) 
    model_version = Column(String(50))
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    application = relationship("Application")


class AIRankingLogs(Base):
    __tablename__ = "ai_ranking_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"), index=True)
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id"), index=True)
    score = Column(DECIMAL(5, 2))
    explanation = Column(Text)
    model_version = Column(String(50))
    created_at = Column(TIMESTAMP, server_default=func.now())

    # Relationships
    job_posting = relationship("JobPosting")
    candidate = relationship("Candidate")


class GeneratedContent(Base):
    __tablename__ = "generated_content"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    job_posting_id = Column(UUID(as_uuid=True), ForeignKey("job_postings.id"), index=True)
    content_type = Column(String(50), nullable=False) # 'JD', 'SOCIAL_POST', 'WELCOME_IMG'
    content_body = Column(Text)
    image_url = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    # Relationships
    job_posting = relationship("JobPosting")


class Employee(Base):
    __tablename__ = "employees"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id"), unique=True)
    employee_id = Column(String(50), unique=True, nullable=False)
    joined_date = Column(Date, nullable=False)
    status = Column(String(50), default="active")
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User")
    candidate = relationship("Candidate")


class DepartmentSkill(Base):
    __tablename__ = "department_skills"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    department = Column(String(100), nullable=False, index=True)
    skill_name = Column(String(100), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    
    __table_args__ = (
        UniqueConstraint('department', 'skill_name', name='_dept_skill_uc'),
    )
