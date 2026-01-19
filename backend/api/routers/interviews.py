from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import uuid

from infrastructure.database.connection import get_db
from infrastructure.database.models import (
    Interview, InterviewPanel, InterviewFeedback,
    Application, User
)
from infrastructure.security.auth import get_current_user
from application.schemas import (
    InterviewCreate,
    InterviewResponse,
    InterviewFeedbackCreate,
    InterviewRescheduleRequest,
    MessageResponse
)

router = APIRouter()


@router.post("/", response_model=InterviewResponse, status_code=status.HTTP_201_CREATED)
async def schedule_interview(
    interview_data: InterviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Schedule a new interview.
    """
    # Verify application exists
    application = db.query(Application).filter(
        Application.id == interview_data.application_id
    ).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    # Create interview
    new_interview = Interview(
        application_id=interview_data.application_id,
        round_number=interview_data.round_number,
        round_name=interview_data.round_name,
        interview_type=interview_data.interview_type,
        scheduled_date=interview_data.scheduled_date,
        duration_minutes=interview_data.duration_minutes,
        location=interview_data.location,
        video_link=interview_data.video_link,
        status="scheduled"
    )
    
    db.add(new_interview)
    db.flush()
    
    # Add interview panel members
    for interviewer_id in interview_data.interviewer_ids:
        panel_member = InterviewPanel(
            interview_id=new_interview.id,
            interviewer_id=interviewer_id,
            role="interviewer"
        )
        db.add(panel_member)
    
    # Update application status
    if application.status not in ["interview", "selected"]:
        application.status = "interview"
    
    db.commit()
    db.refresh(new_interview)
    
    # TODO: Send notifications to candidate and interviewers
    # TODO: Create calendar events
    
    return new_interview


@router.get("/", response_model=List[InterviewResponse])
async def list_interviews(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    status: Optional[str] = None,
    application_id: Optional[str] = None,
    interviewer_id: Optional[str] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all interviews with filtering.
    """
    query = db.query(Interview)
    
    # Apply filters
    if status:
        query = query.filter(Interview.status == status)
    if application_id:
        query = query.filter(Interview.application_id == application_id)
    if interviewer_id:
        query = query.join(InterviewPanel).filter(InterviewPanel.interviewer_id == interviewer_id)
    if from_date:
        query = query.filter(Interview.scheduled_date >= from_date)
    if to_date:
        query = query.filter(Interview.scheduled_date <= to_date)
    
    interviews = query.order_by(Interview.scheduled_date).offset(skip).limit(limit).all()
    return interviews


@router.get("/{interview_id}", response_model=InterviewResponse)
async def get_interview(
    interview_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get interview details.
    """
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    
    if not interview:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview not found"
        )
    
    return interview


@router.put("/{interview_id}", response_model=InterviewResponse)
async def update_interview(
    interview_id: str,
    interview_data: InterviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update interview details.
    """
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    
    if not interview:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview not found"
        )
    
    # Update fields
    interview.round_name = interview_data.round_name
    interview.interview_type = interview_data.interview_type
    interview.scheduled_date = interview_data.scheduled_date
    interview.duration_minutes = interview_data.duration_minutes
    interview.location = interview_data.location
    interview.video_link = interview_data.video_link
    
    db.commit()
    db.refresh(interview)
    
    return interview


@router.post("/{interview_id}/reschedule", response_model=MessageResponse)
async def reschedule_interview(
    interview_id: str,
    reschedule_data: InterviewRescheduleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Reschedule an interview.
    """
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    
    if not interview:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview not found"
        )
    
    if interview.status == "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot reschedule completed interview"
        )
    
    interview.scheduled_date = reschedule_data.new_scheduled_date
    interview.reschedule_count += 1
    interview.reschedule_reason = reschedule_data.reason
    interview.status = "rescheduled"
    
    db.commit()
    
    # TODO: Send notifications
    
    return {
        "message": "Interview rescheduled successfully",
        "success": True
    }


@router.post("/{interview_id}/cancel", response_model=MessageResponse)
async def cancel_interview(
    interview_id: str,
    reason: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Cancel an interview.
    """
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    
    if not interview:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview not found"
        )
    
    interview.status = "cancelled"
    interview.meeting_notes = f"Cancelled: {reason}"
    
    db.commit()
    
    return {
        "message": "Interview cancelled successfully",
        "success": True
    }


@router.post("/{interview_id}/complete", response_model=MessageResponse)
async def complete_interview(
    interview_id: str,
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Mark interview as completed.
    """
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    
    if not interview:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview not found"
        )
    
    interview.status = "completed"
    if notes:
        interview.meeting_notes = notes
    
    db.commit()
    
    return {
        "message": "Interview marked as completed",
        "success": True
    }


@router.post("/{interview_id}/feedback", response_model=MessageResponse)
async def submit_interview_feedback(
    interview_id: str,
    feedback_data: InterviewFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Submit interview feedback.
    """
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    
    if not interview:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview not found"
        )
    
    # Check if feedback already exists from this interviewer
    existing_feedback = db.query(InterviewFeedback).filter(
        InterviewFeedback.interview_id == interview_id,
        InterviewFeedback.interviewer_id == current_user.id
    ).first()
    
    if existing_feedback:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Feedback already submitted by this interviewer"
        )
    
    # Calculate overall rating
    overall_rating = (
        feedback_data.technical_skills_rating +
        feedback_data.communication_rating +
        feedback_data.problem_solving_rating +
        feedback_data.cultural_fit_rating
    ) / 4.0
    
    # Create feedback
    feedback = InterviewFeedback(
        interview_id=interview_id,
        interviewer_id=current_user.id,
        technical_skills_rating=feedback_data.technical_skills_rating,
        communication_rating=feedback_data.communication_rating,
        problem_solving_rating=feedback_data.problem_solving_rating,
        cultural_fit_rating=feedback_data.cultural_fit_rating,
        overall_rating=overall_rating,
        strengths=feedback_data.strengths,
        weaknesses=feedback_data.weaknesses,
        comments=feedback_data.comments,
        recommendation=feedback_data.recommendation
    )
    
    db.add(feedback)
    db.commit()
    
    return {
        "message": "Feedback submitted successfully",
        "success": True
    }


@router.get("/{interview_id}/feedback")
async def get_interview_feedback(
    interview_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all feedback for an interview.
    """
    feedback_list = db.query(InterviewFeedback).filter(
        InterviewFeedback.interview_id == interview_id
    ).all()
    
    # Calculate average ratings
    if feedback_list:
        avg_technical = sum(f.technical_skills_rating for f in feedback_list) / len(feedback_list)
        avg_communication = sum(f.communication_rating for f in feedback_list) / len(feedback_list)
        avg_problem_solving = sum(f.problem_solving_rating for f in feedback_list) / len(feedback_list)
        avg_cultural_fit = sum(f.cultural_fit_rating for f in feedback_list) / len(feedback_list)
        avg_overall = sum(f.overall_rating for f in feedback_list) / len(feedback_list)
        
        return {
            "feedback": feedback_list,
            "averages": {
                "technical_skills": round(avg_technical, 2),
                "communication": round(avg_communication, 2),
                "problem_solving": round(avg_problem_solving, 2),
                "cultural_fit": round(avg_cultural_fit, 2),
                "overall": round(avg_overall, 2)
            }
        }
    
    return {"feedback": [], "averages": None}


@router.get("/{interview_id}/panel")
async def get_interview_panel(
    interview_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get interview panel members.
    """
    panel = db.query(InterviewPanel).filter(
        InterviewPanel.interview_id == interview_id
    ).all()
    
    return panel
