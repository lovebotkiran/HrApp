from pydantic import BaseModel, EmailStr, Field
from uuid import UUID
from typing import Optional, List
from datetime import datetime, date
from decimal import Decimal


# ============================================
# USER SCHEMAS
# ============================================

class UserBase(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str
    phone: Optional[str] = None
    department: Optional[str] = None
    designation: Optional[str] = None


class UserCreate(UserBase):
    password: str = Field(..., min_length=8)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(UserBase):
    id: UUID
    is_active: bool
    is_verified: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ============================================
# JOB REQUISITION SCHEMAS
# ============================================

class JobRequisitionBase(BaseModel):
    title: str
    department: str
    position_count: int = 1
    employment_type: str
    experience_min: Optional[int] = None
    experience_max: Optional[int] = None
    salary_min: Optional[Decimal] = None
    salary_max: Optional[Decimal] = None
    currency: str = "INR"
    location: Optional[str] = None
    required_skills: Optional[List[str]] = []
    preferred_skills: Optional[List[str]] = []
    education_requirements: Optional[str] = None
    job_description: Optional[str] = None
    responsibilities: Optional[str] = None
    benefits: Optional[str] = None
    priority: str = "medium"
    target_hire_date: Optional[date] = None
    reason_for_hiring: Optional[str] = None


class JobRequisitionCreate(JobRequisitionBase):
    pass


class JobRequisitionUpdate(BaseModel):
    title: Optional[str] = None
    position_count: Optional[int] = None
    employment_type: Optional[str] = None
    experience_min: Optional[int] = None
    experience_max: Optional[int] = None
    salary_min: Optional[Decimal] = None
    salary_max: Optional[Decimal] = None
    location: Optional[str] = None
    required_skills: Optional[List[str]] = None
    preferred_skills: Optional[List[str]] = None
    job_description: Optional[str] = None
    responsibilities: Optional[str] = None
    benefits: Optional[str] = None
    priority: Optional[str] = None
    target_hire_date: Optional[date] = None


class JobRequisitionResponse(JobRequisitionBase):
    id: UUID
    requisition_number: str
    requested_by: Optional[UUID]
    status: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class JobRequisitionApprovalRequest(BaseModel):
    status: str  # approved, rejected
    comments: Optional[str] = None


# ============================================
# JOB POSTING SCHEMAS
# ============================================

class JobPostingBase(BaseModel):
    title: str
    description: str
    requirements: Optional[str] = None
    responsibilities: Optional[str] = None
    benefits: Optional[str] = None
    location: Optional[str] = None
    employment_type: Optional[str] = None
    experience_min: Optional[int] = None
    experience_max: Optional[int] = None
    salary_min: Optional[Decimal] = None
    salary_max: Optional[Decimal] = None
    currency: str = "INR"
    skills_required: Optional[List[str]] = []
    expires_at: Optional[datetime] = None


class JobPostingCreate(JobPostingBase):
    requisition_id: Optional[UUID] = None


class JobPostingResponse(JobPostingBase):
    id: UUID
    job_code: str
    requisition_id: Optional[UUID]
    is_active: bool
    published_at: Optional[datetime]
    views_count: int
    applications_count: int
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============================================
# CANDIDATE SCHEMAS
# ============================================

class CandidateBase(BaseModel):
    email: EmailStr
    phone: Optional[str] = None
    first_name: str
    last_name: str
    current_location: Optional[str] = None
    preferred_location: Optional[str] = None
    current_company: Optional[str] = None
    current_designation: Optional[str] = None
    total_experience_years: Optional[Decimal] = None
    current_ctc: Optional[Decimal] = None
    expected_ctc: Optional[Decimal] = None
    notice_period_days: Optional[int] = None
    highest_education: Optional[str] = None
    linkedin_url: Optional[str] = None
    portfolio_url: Optional[str] = None
    skills: Optional[List[str]] = []
    certifications: Optional[List[str]] = []
    languages: Optional[List[str]] = []


class CandidateCreate(CandidateBase):
    pass


class CandidateResponse(CandidateBase):
    id: UUID
    resume_url: Optional[str]
    resume_parsed_data: Optional[dict]
    is_blacklisted: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============================================
# APPLICATION SCHEMAS
# ============================================

class ApplicationBase(BaseModel):
    job_posting_id: UUID
    source: str
    cover_letter: Optional[str] = None


class ApplicationCreate(ApplicationBase):
    candidate_data: CandidateCreate
    resume_file: Optional[str] = None  # Will be handled as file upload


class ApplicationResponse(BaseModel):
    id: UUID
    application_number: str
    job_posting_id: UUID
    candidate_id: UUID
    source: str
    status: str
    ai_match_score: Optional[Decimal]
    ai_match_reasoning: Optional[str]
    applied_at: datetime
    
    class Config:
        from_attributes = True


class ApplicationStatusUpdate(BaseModel):
    status: str
    notes: Optional[str] = None


# ============================================
# INTERVIEW SCHEMAS
# ============================================

class InterviewBase(BaseModel):
    round_number: int
    round_name: Optional[str] = None
    interview_type: str
    scheduled_date: datetime
    duration_minutes: int = 60
    location: Optional[str] = None
    video_link: Optional[str] = None


class InterviewCreate(InterviewBase):
    application_id: UUID
    interviewer_ids: List[UUID]


class InterviewResponse(InterviewBase):
    id: UUID
    application_id: UUID
    status: str
    reschedule_count: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class InterviewFeedbackCreate(BaseModel):
    technical_skills_rating: int = Field(..., ge=1, le=5)
    communication_rating: int = Field(..., ge=1, le=5)
    problem_solving_rating: int = Field(..., ge=1, le=5)
    cultural_fit_rating: int = Field(..., ge=1, le=5)
    strengths: Optional[str] = None
    weaknesses: Optional[str] = None
    comments: Optional[str] = None
    recommendation: str


class InterviewRescheduleRequest(BaseModel):
    new_scheduled_date: datetime
    reason: str


# ============================================
# OFFER SCHEMAS
# ============================================

class OfferBase(BaseModel):
    designation: str
    department: Optional[str] = None
    annual_ctc: Decimal
    base_salary: Decimal
    bonus: Optional[Decimal] = None
    benefits: Optional[dict] = None
    joining_date: date
    offer_valid_until: date
    employment_type: Optional[str] = None
    location: Optional[str] = None
    reporting_to: Optional[str] = None
    probation_period_months: Optional[int] = None
    notice_period_days: Optional[int] = None


class OfferCreate(OfferBase):
    application_id: UUID
    candidate_id: UUID
    job_posting_id: UUID


class OfferResponse(OfferBase):
    id: UUID
    offer_number: str
    application_id: UUID
    candidate_id: UUID
    job_posting_id: UUID
    status: str
    offer_letter_url: Optional[str]
    sent_at: Optional[datetime]
    accepted_at: Optional[datetime]
    created_at: datetime
    
    class Config:
        from_attributes = True


class OfferApprovalRequest(BaseModel):
    status: str  # approved, rejected
    comments: Optional[str] = None


class OfferAcceptanceRequest(BaseModel):
    accepted: bool
    rejection_reason: Optional[str] = None
    digital_signature: Optional[str] = None  # Base64 encoded signature


# ============================================
# ANALYTICS SCHEMAS
# ============================================

class RecruitmentPipelineStats(BaseModel):
    applied: int
    screening: int
    shortlisted: int
    interview: int
    selected: int
    offered: int
    onboarded: int


class RecruitmentMetrics(BaseModel):
    total_applications: int
    total_hires: int
    average_time_to_hire_days: Optional[Decimal]
    average_cost_per_hire: Optional[Decimal]
    offer_acceptance_rate: Optional[Decimal]
    source_effectiveness: dict


# ============================================
# COMMON SCHEMAS
# ============================================

class PaginationParams(BaseModel):
    skip: int = 0
    limit: int = 100


class PaginatedResponse(BaseModel):
    total: int
    skip: int
    limit: int
    items: List[dict]


class MessageResponse(BaseModel):
    message: str
    success: bool = True
