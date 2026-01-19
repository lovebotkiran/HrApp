from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uuid

from infrastructure.database.connection import get_db
from infrastructure.database.models import User, JobPosting, JobPostingPlatform, JobRequisition
from infrastructure.security.auth import get_current_user
from application.schemas import (
    JobPostingCreate,
    JobPostingResponse,
    MessageResponse
)
from application.services.ai_service import AIService

router = APIRouter()
ai_service = AIService()


@router.post("/", response_model=JobPostingResponse, status_code=status.HTTP_201_CREATED)
async def create_job_posting(
    posting_data: JobPostingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new job posting from an approved requisition.
    """
    # Verify requisition exists and is approved
    if posting_data.requisition_id:
        requisition = db.query(JobRequisition).filter(
            JobRequisition.id == posting_data.requisition_id
        ).first()
        
        if not requisition:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Job requisition not found"
            )
        
        if requisition.status != "approved":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only create postings from approved requisitions"
            )
    
    # Generate job code
    job_code = f"JOB-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
    
    # Create posting
    new_posting = JobPosting(
        job_code=job_code,
        **posting_data.dict()
    )
    
    db.add(new_posting)
    db.commit()
    db.refresh(new_posting)
    
    return new_posting


@router.get("/", response_model=List[JobPostingResponse])
async def list_job_postings(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    is_active: Optional[bool] = None,
    employment_type: Optional[str] = None,
    location: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    List all job postings (public endpoint).
    Filter by active status, employment type, and location.
    """
    query = db.query(JobPosting)
    
    # Apply filters
    if is_active is not None:
        query = query.filter(JobPosting.is_active == is_active)
    if employment_type:
        query = query.filter(JobPosting.employment_type == employment_type)
    if location:
        query = query.filter(JobPosting.location.ilike(f"%{location}%"))
    
    # Filter out expired postings
    query = query.filter(
        (JobPosting.expires_at.is_(None)) | (JobPosting.expires_at > datetime.utcnow())
    )
    
    postings = query.order_by(JobPosting.created_at.desc()).offset(skip).limit(limit).all()
    return postings


@router.get("/{posting_id}", response_model=JobPostingResponse)
async def get_job_posting(
    posting_id: str,
    db: Session = Depends(get_db)
):
    """
    Get a specific job posting by ID.
    Increments view count.
    """
    posting = db.query(JobPosting).filter(JobPosting.id == posting_id).first()
    
    if not posting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job posting not found"
        )
    
    # Increment view count
    posting.views_count += 1
    db.commit()
    
    return posting


@router.put("/{posting_id}", response_model=JobPostingResponse)
async def update_job_posting(
    posting_id: str,
    posting_data: JobPostingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update a job posting.
    """
    posting = db.query(JobPosting).filter(JobPosting.id == posting_id).first()
    
    if not posting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job posting not found"
        )
    
    # Update fields
    update_data = posting_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(posting, field, value)
    
    db.commit()
    db.refresh(posting)
    
    return posting


@router.delete("/{posting_id}", response_model=MessageResponse)
async def delete_job_posting(
    posting_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Deactivate a job posting (soft delete).
    """
    posting = db.query(JobPosting).filter(JobPosting.id == posting_id).first()
    
    if not posting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job posting not found"
        )
    
    posting.is_active = False
    db.commit()
    
    return {
        "message": "Job posting deactivated successfully",
        "success": True
    }


@router.post("/{posting_id}/publish", response_model=MessageResponse)
async def publish_job_posting(
    posting_id: str,
    platforms: List[str] = Query(..., description="Platforms to publish to"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Publish job posting to multiple platforms.
    Platforms: career_page, linkedin, naukri, indeed, etc.
    Triggers AI generation for social media posts.
    """
    posting = db.query(JobPosting).filter(JobPosting.id == posting_id).first()
    
    if not posting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job posting not found"
        )
    
    # Mark as published
    if not posting.published_at:
        posting.published_at = datetime.utcnow()
    
    posting.is_active = True
    
    success_count = 0 

    # Create platform entries
    for platform in platforms:
        # Check if already posted to this platform
        existing = db.query(JobPostingPlatform).filter(
            JobPostingPlatform.job_posting_id == posting_id,
            JobPostingPlatform.platform == platform
        ).first()
        
        if not existing:
            # Simulate external API call
            # In a real app, this would use LinkedIn API etc.
            
            # Generate Social Media Content via AI
            # content = await ai_service.generate_social_post(posting, platform)
            
            # Placeholder for now
            status_msg = "posted"
            
            platform_entry = JobPostingPlatform(
                job_posting_id=posting_id,
                platform=platform,
                posted_at=datetime.utcnow(),
                status=status_msg
            )
            db.add(platform_entry)
            success_count += 1
    
    db.commit()
    
    return {
        "message": f"Job posting publishing initiated for {success_count} new platform(s)",
        "success": True
    }


@router.get("/{posting_id}/platforms")
async def get_posting_platforms(
    posting_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all platforms where this job is posted.
    """
    platforms = db.query(JobPostingPlatform).filter(
        JobPostingPlatform.job_posting_id == posting_id
    ).all()
    
    return platforms


@router.post("/{posting_id}/expire", response_model=MessageResponse)
async def expire_job_posting(
    posting_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Manually expire a job posting.
    """
    posting = db.query(JobPosting).filter(JobPosting.id == posting_id).first()
    
    if not posting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job posting not found"
        )
    
    posting.expires_at = datetime.utcnow()
    posting.is_active = False
    db.commit()
    
    return {
        "message": "Job posting expired successfully",
        "success": True
    }
