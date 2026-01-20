from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uuid

from infrastructure.database.connection import get_db
from infrastructure.database.models import User, JobRequisition, JobRequisitionApproval
from infrastructure.security.auth import get_current_user
from application.schemas import (
    JobRequisitionCreate,
    JobRequisitionUpdate,
    JobRequisitionResponse,
    JobRequisitionApprovalRequest,
    MessageResponse,
    PaginatedResponse
)
from core.config import settings
from application.services.ai_service import AIService
from application.services.linkedin_service import LinkedInService

router = APIRouter()
ai_service = AIService()
linkedin_service = LinkedInService()


@router.post("/", response_model=JobRequisitionResponse, status_code=status.HTTP_201_CREATED)
async def create_job_requisition(
    requisition_data: JobRequisitionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new job requisition.
    """
    # Generate requisition number
    requisition_number = f"REQ-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
    
    # Create requisition
    new_requisition = JobRequisition(
        requisition_number=requisition_number,
        requested_by=current_user.id,
        **requisition_data.dict()
    )
    
    db.add(new_requisition)
    db.commit()
    db.refresh(new_requisition)
    
    # Create approval workflow only if status is pending_approval
    if new_requisition.status == "pending_approval":
        approval_levels = [
            {"level": 1, "role": "manager"},
            {"level": 2, "role": "hr"},
            {"level": 3, "role": "director"}
        ]
        
        for level_info in approval_levels:
            approval = JobRequisitionApproval(
                requisition_id=new_requisition.id,
                approval_level=level_info["level"],
                status="pending"
            )
            db.add(approval)
        
        db.commit()
    
    return new_requisition


@router.get("/", response_model=List[JobRequisitionResponse])
async def list_job_requisitions(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    status: Optional[str] = None,
    department: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all job requisitions with optional filters.
    """
    query = db.query(JobRequisition)
    
    # Apply filters
    # Apply filters
    if status:
        # Handle potential inconsistencies in status naming (legacy data)
        if status == 'pending_approval':
            query = query.filter(JobRequisition.status.in_(['pending_approval', 'Pending Approval']))
        elif status == 'draft':
            query = query.filter(JobRequisition.status.in_(['draft', 'Draft']))
        elif status == 'approved':
            query = query.filter(JobRequisition.status.in_(['approved', 'Approved']))
        elif status == 'rejected':
            query = query.filter(JobRequisition.status.in_(['rejected', 'Rejected']))
        else:
            query = query.filter(JobRequisition.status == status)
    if department:
        query = query.filter(JobRequisition.department == department)
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (JobRequisition.title.ilike(search_term)) | 
            (JobRequisition.department.ilike(search_term)) |
            (JobRequisition.requisition_number.ilike(search_term))
        )
    
    # For non-admin users, show only their department's requisitions
    # This can be enhanced with proper RBAC
    
    # Sort by created_at descending
    requisitions = query.order_by(JobRequisition.created_at.desc()).offset(skip).limit(limit).all()
    return requisitions


@router.get("/{requisition_id}", response_model=JobRequisitionResponse)
async def get_job_requisition(
    requisition_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific job requisition by ID.
    """
    requisition = db.query(JobRequisition).filter(JobRequisition.id == requisition_id).first()
    
    if not requisition:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job requisition not found"
        )
    
    return requisition


@router.put("/{requisition_id}", response_model=JobRequisitionResponse)
async def update_job_requisition(
    requisition_id: str,
    requisition_data: JobRequisitionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update a job requisition.
    """
    requisition = db.query(JobRequisition).filter(JobRequisition.id == requisition_id).first()
    
    if not requisition:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job requisition not found"
        )
    
    # Check if user has permission to update
    if requisition.requested_by != current_user.id:
        # Add proper RBAC check here
        pass
    
    # Only allow updates if status is draft or pending
    if requisition.status not in ["draft", "pending_approval"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot update requisition in current status"
        )
    
    # Update fields
    old_status = requisition.status
    update_data = requisition_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(requisition, field, value)
    
    # If status changed to pending_approval, create approvals if they don't exist
    if old_status == "draft" and requisition.status == "pending_approval":
        # Check if approvals already exist
        existing_approvals = db.query(JobRequisitionApproval).filter(
            JobRequisitionApproval.requisition_id == requisition_id
        ).count()
        
        if existing_approvals == 0:
            approval_levels = [
                {"level": 1, "role": "manager"},
                {"level": 2, "role": "hr"},
                {"level": 3, "role": "director"}
            ]
            
            for level_info in approval_levels:
                approval = JobRequisitionApproval(
                    requisition_id=requisition.id,
                    approval_level=level_info["level"],
                    status="pending"
                )
                db.add(approval)
    
    db.commit()
    db.refresh(requisition)
    
    return requisition


@router.delete("/{requisition_id}", response_model=MessageResponse)
async def delete_job_requisition(
    requisition_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a job requisition (soft delete by changing status).
    """
    requisition = db.query(JobRequisition).filter(JobRequisition.id == requisition_id).first()
    
    if not requisition:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job requisition not found"
        )
    
    # Check permissions
    if requisition.requested_by != current_user.id:
        # Add proper RBAC check
        pass
    
    # Only allow deletion if status is draft
    if requisition.status != "draft":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only delete draft requisitions"
        )
    
    requisition.status = "closed"
    db.commit()
    
    return {
        "message": "Job requisition deleted successfully",
        "success": True
    }


@router.post("/{requisition_id}/approve", response_model=MessageResponse)
async def approve_job_requisition(
    requisition_id: str,
    approval_data: JobRequisitionApprovalRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Approve or reject a job requisition.
    """
    requisition = db.query(JobRequisition).filter(JobRequisition.id == requisition_id).first()
    
    if not requisition:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job requisition not found"
        )
    
    # Find pending approval for current user
    # This is simplified - should check user's role and approval level
    approval = db.query(JobRequisitionApproval).filter(
        JobRequisitionApproval.requisition_id == requisition_id,
        JobRequisitionApproval.status == "pending"
    ).order_by(JobRequisitionApproval.approval_level).first()
    
    if not approval:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No pending approval found"
        )
    
    # Update approval
    approval.approver_id = current_user.id
    approval.status = approval_data.status
    approval.comments = approval_data.comments
    approval.approved_at = datetime.utcnow()
    
    # Update requisition status
    if approval_data.status == "rejected":
        requisition.status = "rejected"
    elif approval_data.status == "approved":
        # Check if all approvals are complete
        pending_approvals = db.query(JobRequisitionApproval).filter(
            JobRequisitionApproval.requisition_id == requisition_id,
            JobRequisitionApproval.status == "pending"
        ).count()
        
        if pending_approvals == 0:
            requisition.status = "approved"
        else:
            requisition.status = "pending_approval"
    
    db.commit()

    # Automatically create Job Posting if approved
    if requisition.status == "approved":
        # Check if job posting already exists
        from infrastructure.database.models import JobPosting
        
        existing_posting = db.query(JobPosting).filter(
            JobPosting.requisition_id == requisition.id
        ).first()
        
        if not existing_posting:
            # Create new job posting
            new_posting = JobPosting(
                requisition_id=requisition.id,
                job_code=requisition.requisition_number,
                title=requisition.title,
                description=requisition.job_description or "Detailed job description to be added.",
                responsibilities=requisition.responsibilities,
                benefits=requisition.benefits,
                location=requisition.location,
                employment_type=requisition.employment_type,
                experience_min=requisition.experience_min,
                experience_max=requisition.experience_max,
                salary_min=requisition.salary_min,
                salary_max=requisition.salary_max,
                currency=requisition.currency,
                skills_required=requisition.required_skills,
                is_active=True,
                published_at=datetime.utcnow(),
                # Default expiration to 30 days from now? Or leave null.
                # Let's set it to target_hire_date if available, else 30 days
            )
            
            if requisition.target_hire_date:
                # Convert date to datetime
                new_posting.expires_at = datetime.combine(requisition.target_hire_date, datetime.min.time())
            
            db.add(new_posting)
            db.commit()
    
    return {
        "message": f"Requisition {approval_data.status} successfully",
        "success": True
    }


@router.post("/{requisition_id}/generate-jd", response_model=MessageResponse)
async def generate_job_description(
    requisition_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    AI-generate job description for a requisition.
    Uses AI Service (Ollama).
    """
    requisition = db.query(JobRequisition).filter(JobRequisition.id == requisition_id).first()
    
    if not requisition:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job requisition not found"
        )
    
    # Use AI Service
    # We pass the requisition details
    generated_jd = await ai_service.generate_jd(
        title=requisition.title,
        skills=requisition.required_skills or [],
        experience_min=requisition.experience_min,
        experience_max=requisition.experience_max
    )
    
    # Append other details if not included by AI (though prompt handles most)
    
    requisition.job_description = generated_jd
    db.commit()
    
    return {
        "message": "Job description generated successfully",
        "success": True
    }


@router.post("/{requisition_id}/share-linkedin", response_model=MessageResponse)
async def share_requisition_linkedin(
    requisition_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Share an approved job requisition to LinkedIn.
    """
    requisition = db.query(JobRequisition).filter(JobRequisition.id == requisition_id).first()
    
    if not requisition:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job requisition not found"
        )
    
    if requisition.status != "approved":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only share approved requisitions"
        )
        
    if not requisition.job_description:
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Job requisition must have a description to be shared"
        )

    if not settings.LINKEDIN_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="LinkedIn sharing is currently disabled in settings"
        )
        
    # Find associated Job Posting to get the ID for the URL
    from infrastructure.database.models import JobPosting
    posting = db.query(JobPosting).filter(
        JobPosting.requisition_id == requisition.id 
    ).first()
    
    # If no posting exists (should have been auto-created), fall back to requisition ID
    target_id = posting.id if posting else requisition.id

    # Construct apply URL matching frontend route /apply/{id}
    # Note: Using hash routing if applicable, e.g. /#/apply/
    # If settings.FRONTEND_URL includes trailing slash, handle it
    base_url = settings.FRONTEND_URL.rstrip('/')
    apply_url = f"{base_url}/#/apply/{target_id}"
    
    result = await linkedin_service.share_job(
        title=requisition.title,
        description=requisition.job_description,
        apply_url=apply_url
    )
    
    if not result.get("success"):
        # If we have a specific status code from LinkedIn (like 401), use it
        error_status = result.get("status_code", status.HTTP_500_INTERNAL_SERVER_ERROR)
        raise HTTPException(
            status_code=error_status,
            detail=result.get("message", "Failed to share to LinkedIn")
        )
        
    return {
        "message": "Successfully shared to LinkedIn",
        "success": True
    }
