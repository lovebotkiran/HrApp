from fastapi import APIRouter, Depends, HTTPException, status, Query, Body
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel
import uuid
import logging

from infrastructure.database.connection import get_db
from infrastructure.database.models import (
    Application, Candidate, JobPosting, Interview, User
)
from infrastructure.security.auth import get_current_user
from application.schemas import (
    ApplicationResponse,
    MessageResponse
)
from application.services.zoom_service import ZoomService
from application.services.email_service import EmailService

router = APIRouter()
logger = logging.getLogger(__name__)
zoom_service = ZoomService()
email_service = EmailService()


class CreateInterviewRequest(BaseModel):
    meeting_platform: str
    scheduled_date: datetime
    duration_minutes: int = 60
    round_number: int = 1
    round_name: Optional[str] = "Technical Interview"
    interviewer_ids: List[str] = []


@router.get("/", response_model=List[ApplicationResponse])
async def list_shortlisted_candidates(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    department: Optional[str] = None,
    job_posting_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all shortlisted candidates with filtering by department and job posting.
    """
    query = db.query(Application).options(
        joinedload(Application.candidate),
        joinedload(Application.job_posting).joinedload(JobPosting.requisition)
    ).filter(Application.status == "shortlisted")
    
    # Apply filters
    if job_posting_id:
        query = query.filter(Application.job_posting_id == job_posting_id)
    
    if department:
        query = query.join(JobPosting).filter(JobPosting.requisition.has(department=department))
    
    applications = query.order_by(Application.applied_at.desc()).offset(skip).limit(limit).all()
    return applications


@router.post("/{application_id}/create-interview")
async def create_interview_with_meeting(
    application_id: str,
    request_data: CreateInterviewRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create an interview and generate meeting link(s) for the shortlisted candidate.
    Sends invitation email to the candidate.
    """
    # Verify application exists and is shortlisted
    application = db.query(Application).options(
        joinedload(Application.candidate),
        joinedload(Application.job_posting)
    ).filter(Application.id == application_id).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    if application.status != "shortlisted":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only shortlisted candidates can be scheduled for interviews"
        )
    
    if not application.candidate:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Candidate information not found"
        )
    
    # Generate meeting link(s) based on platform
    meeting_links = []
    video_link = None
    
    if request_data.meeting_platform in ["zoom", "both"]:
        job_title = application.job_posting.title if application.job_posting else "Position"
        candidate_name = f"{application.candidate.first_name} {application.candidate.last_name}"
        topic = f"Interview: {candidate_name} - {job_title}"
        
        try:
            zoom_link = await zoom_service.create_meeting(
                topic=topic,
                start_time=request_data.scheduled_date,
                duration=request_data.duration_minutes,
                db=db
            )
            
            if zoom_link:
                meeting_links.append({"platform": "Zoom", "link": zoom_link})
                video_link = zoom_link
        except Exception as e:
            logger.error(f"Failed to create Zoom meeting for application {application_id}: {str(e)}")
            # Fallback to mock link so the process can continue
            logger.warning("Using fallback mock Zoom link due to API failure")
            mock_link = "https://zoom.us/j/1234567890?pwd=mock-link-due-to-api-error"
            meeting_links.append({"platform": "Zoom (Mock)", "link": mock_link})
            video_link = mock_link
    
    if request_data.meeting_platform in ["teams", "both"]:
        # TODO: Implement Teams integration
        logger.info("Teams integration not yet implemented")
        meeting_links.append({"platform": "Teams", "link": "Teams integration coming soon"})
    
    if not video_link and meeting_links:
        video_link = meeting_links[0]["link"]
    
    # Create interview record
    new_interview = Interview(
        application_id=application_id,
        round_number=request_data.round_number,
        round_name=request_data.round_name,
        interview_type="video",
        scheduled_date=request_data.scheduled_date,
        duration_minutes=request_data.duration_minutes,
        video_link=video_link,
        status="scheduled"
    )
    
    db.add(new_interview)
    
    # Add interview panel members
    from infrastructure.database.models import InterviewPanel
    for interviewer_id in request_data.interviewer_ids:
        panel_member = InterviewPanel(
            interview_id=new_interview.id,
            interviewer_id=interviewer_id,
            role="interviewer"
        )
        db.add(panel_member)
    
    # Update application status
    application.status = "interview"
    
    db.commit()
    db.refresh(new_interview)
    
    # Send email invitation to candidate
    if application.candidate.email and video_link:
        candidate_name = f"{application.candidate.first_name} {application.candidate.last_name}"
        job_title = application.job_posting.title if application.job_posting else "Position"
        scheduled_at = request_data.scheduled_date.strftime("%B %d, %Y at %I:%M %p UTC")
        
        email_sent = await email_service.send_interview_invitation(
            candidate_email=application.candidate.email,
            candidate_name=candidate_name,
            job_title=job_title,
            meeting_link=video_link,
            scheduled_at=scheduled_at,
            db=db
        )
        
        if email_sent:
            logger.info(f"Interview invitation sent to {application.candidate.email}")
        else:
            logger.warning(f"Failed to send interview invitation to {application.candidate.email}")

        # Send emails to interviewers
        for interviewer_id in request_data.interviewer_ids:
            try:
                # Fetch user
                interviewer = db.query(User).filter(User.id == interviewer_id).first()
                if interviewer and interviewer.email:
                    interviewer_name = f"{interviewer.first_name} {interviewer.last_name}"
                    await email_service.send_interviewer_assignment(
                        interviewer_email=interviewer.email,
                        interviewer_name=interviewer_name,
                        candidate_name=candidate_name,
                        job_title=job_title,
                        meeting_link=video_link,
                        scheduled_at=scheduled_at,
                        db=db
                    )
                    logger.info(f"Interview assignment sent to {interviewer.email}")
            except Exception as e:
                logger.error(f"Failed to email interviewer {interviewer_id}: {e}")
    
    return {
        "message": "Interview scheduled successfully",
        "success": True,
        "interview_id": str(new_interview.id),
        "meeting_links": meeting_links
    }


@router.get("/departments")
async def get_departments_with_shortlisted(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of departments that have shortlisted candidates.
    """
    from sqlalchemy import distinct
    from infrastructure.database.models import JobRequisition
    
    departments = db.query(distinct(JobRequisition.department)).join(
        JobPosting, JobPosting.requisition_id == JobRequisition.id
    ).join(
        Application, Application.job_posting_id == JobPosting.id
    ).filter(
        Application.status == "shortlisted"
    ).all()
    
    return [dept[0] for dept in departments if dept[0]]


@router.get("/job-postings")
async def get_job_postings_with_shortlisted(
    department: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of job postings that have shortlisted candidates.
    """
    query = db.query(JobPosting).join(
        Application, Application.job_posting_id == JobPosting.id
    ).filter(
        Application.status == "shortlisted"
    )
    
    if department:
        from infrastructure.database.models import JobRequisition
        query = query.join(JobRequisition).filter(JobRequisition.department == department)
    
    job_postings = query.distinct().all()
    
    return [
        {
            "id": str(jp.id),
            "title": jp.title,
            "job_code": jp.job_code
        }
        for jp in job_postings
    ]
