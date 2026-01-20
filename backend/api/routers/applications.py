from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uuid
import logging

from infrastructure.database.connection import get_db
from infrastructure.database.models import (
    Application, Candidate, JobPosting, User
)
from infrastructure.security.auth import get_current_user
from application.schemas import (
    ApplicationCreate,
    ApplicationResponse,
    ApplicationStatusUpdate,
    CandidateCreate,
    MessageResponse
)
from application.services.ai_service import AIService

router = APIRouter()
ai_service = AIService()
logger = logging.getLogger(__name__)


@router.post("/", response_model=ApplicationResponse, status_code=status.HTTP_201_CREATED)
async def submit_application(
    application_data: ApplicationCreate,
    db: Session = Depends(get_db)
):
    """
    Submit a job application.
    Creates candidate profile if doesn't exist.
    """
    # Verify job posting exists
    job_posting = db.query(JobPosting).filter(
        JobPosting.id == application_data.job_posting_id
    ).first()
    
    if not job_posting or not job_posting.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job posting not found or inactive"
        )
    
    # Create or get candidate
    candidate = db.query(Candidate).filter(
        Candidate.email == application_data.candidate_data.email
    ).first()
    
    if not candidate:
        candidate = Candidate(**application_data.candidate_data.dict())
        db.add(candidate)
        db.flush()
    
    # Check for duplicate application
    existing_app = db.query(Application).filter(
        Application.job_posting_id == application_data.job_posting_id,
        Application.candidate_id == candidate.id
    ).first()
    
    if existing_app:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Candidate has already applied for this position"
        )
    
    # Generate application number
    app_number = f"APP-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
    
    # Create application
    new_application = Application(
        application_number=app_number,
        job_posting_id=application_data.job_posting_id,
        candidate_id=candidate.id,
        source=application_data.source,
        cover_letter=application_data.cover_letter,
        status="applied"
    )
    
    db.add(new_application)
    
    # Update job posting application count
    job_posting.applications_count += 1
    
    # Calculate AI match score if candidate has parsed data
    if candidate.resume_parsed_data and job_posting.description:
        try:
            result = await ai_service.rank_candidate(
                job_description=job_posting.description,
                candidate_profile_json=candidate.resume_parsed_data
            )
            new_application.ai_match_score = result.get("score", 0)
            new_application.ai_match_reasoning = result.get("reasoning", "AI calculated score")
        except Exception as e:
            logger.error(f"Error calculating AI match score: {e}")
            new_application.ai_match_score = 0
            new_application.ai_match_reasoning = f"AI Error: {str(e)}"
    else:
        # For now, set a placeholder if no data available
        new_application.ai_match_score = 0
        new_application.ai_match_reasoning = "Awaiting resume parsing for AI matching"
    
    db.commit()
    db.refresh(new_application)
    
    return new_application


@router.get("/", response_model=List[ApplicationResponse])
async def list_applications(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    status: Optional[str] = None,
    job_posting_id: Optional[str] = None,
    candidate_id: Optional[str] = None,
    source: Optional[str] = None,
    min_match_score: Optional[float] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all applications with filtering.
    """
    from sqlalchemy.orm import joinedload
    query = db.query(Application).options(
        joinedload(Application.candidate),
        joinedload(Application.job_posting)
    )
    
    # Apply filters
    if status:
        query = query.filter(Application.status == status)
    if job_posting_id:
        query = query.filter(Application.job_posting_id == job_posting_id)
    if candidate_id:
        query = query.filter(Application.candidate_id == candidate_id)
    if source:
        query = query.filter(Application.source == source)
    if min_match_score:
        query = query.filter(Application.ai_match_score >= min_match_score)
    
    applications = query.order_by(Application.applied_at.desc()).offset(skip).limit(limit).all()
    return applications


@router.get("/{application_id}", response_model=ApplicationResponse)
async def get_application(
    application_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get application details.
    """
    application = db.query(Application).filter(Application.id == application_id).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    return application


@router.put("/{application_id}/status", response_model=MessageResponse)
async def update_application_status(
    application_id: str,
    status_data: ApplicationStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update application status.
    Valid statuses: applied, screening, shortlisted, interview, selected, offered, rejected, withdrawn
    """
    application = db.query(Application).filter(Application.id == application_id).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    valid_statuses = [
        "applied", "screening", "shortlisted", "interview",
        "selected", "offered", "rejected", "withdrawn"
    ]
    
    if status_data.status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
        )
    
    application.status = status_data.status
    db.commit()
    
    # Send notification to candidate
    logger.info(f"NOTIFICATION: Application {application_id} status updated to {status_data.status} for candidate {application.candidate_id}")
    # TODO: Implement real email/SMS notification service
    
    return {
        "message": f"Application status updated to {status_data.status}",
        "success": True
    }


@router.post("/{application_id}/shortlist", response_model=MessageResponse)
async def shortlist_application(
    application_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Shortlist an application.
    """
    application = db.query(Application).filter(Application.id == application_id).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    if application.status not in ["applied", "screening"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only shortlist applications in 'applied' or 'screening' status"
        )
    
    application.status = "shortlisted"
    db.commit()
    
    return {
        "message": "Application shortlisted successfully",
        "success": True
    }


@router.post("/{application_id}/reject", response_model=MessageResponse)
async def reject_application(
    application_id: str,
    reason: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Reject an application.
    """
    application = db.query(Application).filter(Application.id == application_id).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    application.status = "rejected"
    db.commit()
    
    # Send rejection email to candidate
    logger.info(f"NOTIFICATION: Sending rejection email to candidate {application.candidate_id} for application {application_id}. Reason: {reason}")
    # TODO: Implement real email service
    
    return {
        "message": "Application rejected",
        "success": True
    }


@router.post("/{application_id}/assessment", response_model=MessageResponse)
async def create_assessment(
    application_id: str,
    assessment_type: str,
    total_questions: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create an assessment for an application.
    Types: screening, aptitude, coding, domain
    """
    application = db.query(Application).filter(Application.id == application_id).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    # TODO: Implement assessment model and creation
    # assessment = CandidateAssessment(
    #     application_id=application_id,
    #     assessment_type=assessment_type,
    #     total_questions=total_questions,
    #     status="pending"
    # )
    # db.add(assessment)
    # db.commit()
    
    return {
        "message": "Assessment feature coming soon",
        "success": True
    }


@router.get("/{application_id}/assessments")
async def get_application_assessments(
    application_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all assessments for an application.
    """
    # TODO: Implement assessment model
    # assessments = db.query(CandidateAssessment).filter(
    #     CandidateAssessment.application_id == application_id
    # ).all()
    
    return []


@router.post("/{application_id}/calculate-match-score", response_model=MessageResponse)
async def calculate_match_score(
    application_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Recalculate AI match score for an application.
    Uses AI Service to compare Resume Parsed Data vs Job Description.
    """
    application = db.query(Application).filter(Application.id == application_id).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    if not application.candidate or not application.candidate.resume_parsed_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Candidate profile or parsed resume data missing"
        )
    
    if not application.job_posting or not application.job_posting.description:
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Job posting description details missing"
        )
    
    # Trigger AI Ranking
    result = await ai_service.rank_candidate(
        job_description=application.job_posting.description,
        candidate_profile_json=application.candidate.resume_parsed_data
    )
    
    # Save to DB
    application.ai_match_score = result.get("score", 0)
    application.ai_match_reasoning = result.get("reasoning", "No explanation provided")
    
    # Check if we should log this in AIRankingLogs (new table)
    # log = AIRankingLogs(
    #    job_posting_id=application.job_posting_id,
    #    candidate_id=application.candidate_id,
    #    score=result.get("score", 0),
    #    explanation=result.get("reasoning"),
    #    model_version="llama3" 
    # )
    # db.add(log)

    db.commit()
    
    return {
        "message": "Match score calculated successfully",
        "success": True
    }


@router.post("/rank-by-job-posting/{job_posting_id}", response_model=MessageResponse)
async def rank_applications_by_job_posting(
    job_posting_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Rank all applications for a specific job posting using AI.
    This will parse resumes and calculate match scores for all candidates.
    """
    # Verify job posting exists
    job_posting = db.query(JobPosting).filter(JobPosting.id == job_posting_id).first()
    
    if not job_posting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job posting not found"
        )
    
    if not job_posting.description:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Job posting must have a description to rank candidates"
        )
    
    # Get all applications for this job posting
    applications = db.query(Application).filter(
        Application.job_posting_id == job_posting_id
    ).all()
    
    if not applications:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No applications found for this job posting"
        )
    
    ranked_count = 0
    skipped_count = 0
    
    for application in applications:
        try:
            # Parse resume if not already parsed
            if application.candidate and application.candidate.resume_url:
                if not application.candidate.resume_parsed_data:
                    parsed_data = await ai_service.parse_resume(
                        application.candidate.resume_url,
                        "application/pdf"
                    )
                    
                    if "error" not in parsed_data:
                        application.candidate.resume_parsed_data = parsed_data
                        application.candidate.skills = parsed_data.get("skills", [])
                        application.candidate.total_experience_years = parsed_data.get("total_experience_years")
            
            # Rank candidate if we have parsed data
            if application.candidate and application.candidate.resume_parsed_data:
                result = await ai_service.rank_candidate(
                    job_description=job_posting.description,
                    candidate_profile_json=application.candidate.resume_parsed_data
                )
                
                application.ai_match_score = result.get("score", 0)
                application.ai_match_reasoning = result.get("reasoning", "No explanation provided")
                ranked_count += 1
            else:
                skipped_count += 1
                
        except Exception as e:
            logger.error(f"Error ranking application {application.id}: {e}")
            skipped_count += 1
            continue
    
    db.commit()
    
    return {
        "message": f"Ranked {ranked_count} applications successfully. Skipped {skipped_count}.",
        "success": True
    }


@router.post("/rank-all", response_model=MessageResponse)
async def rank_all_applications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Rank all applications that don't have an AI score yet.
    """
    applications = db.query(Application).filter(
        Application.ai_match_score == None
    ).all()
    
    if not applications:
        return {
            "message": "No new applications to rank",
            "success": True
        }
    
    ranked_count = 0
    error_count = 0
    
    for app in applications:
        try:
            if not app.job_posting or not app.job_posting.description:
                continue
                
            # Trigger ranking
            result = await ai_service.rank_candidate(
                job_description=app.job_posting.description,
                candidate_profile_json=app.candidate.resume_parsed_data if app.candidate.resume_parsed_data else {}
            )
            
            app.ai_match_score = result.get("score", 0)
            app.ai_match_reasoning = result.get("reasoning", "No explanation provided")
            ranked_count += 1
        except Exception as e:
            logger.error(f"Error ranking application {app.id}: {e}")
            error_count += 1
            
    db.commit()
    
    return {
        "message": f"Successfully ranked {ranked_count} applications. {error_count} errors.",
        "success": True
    }
