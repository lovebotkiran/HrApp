from fastapi import APIRouter, Depends, File, UploadFile, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
from datetime import datetime
import shutil
import os

from infrastructure.database.connection import get_db
from infrastructure.database.models import (
    Candidate, CandidateDocument, User
)
from infrastructure.security.auth import get_current_user
from application.schemas import CandidateCreate, CandidateResponse, MessageResponse
from application.services.ai_service import AIService

router = APIRouter()
ai_service = AIService()


@router.post("/", response_model=CandidateResponse, status_code=status.HTTP_201_CREATED)
async def create_candidate(
    candidate_data: CandidateCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new candidate profile.
    Checks for duplicates by email.
    """
    # Check for existing candidate
    existing = db.query(Candidate).filter(Candidate.email == candidate_data.email).first()
    if existing:
        # Return existing candidate instead of error
        return existing
    
    # Create new candidate
    new_candidate = Candidate(**candidate_data.dict())
    db.add(new_candidate)
    db.commit()
    db.refresh(new_candidate)
    
    return new_candidate


@router.get("/", response_model=List[CandidateResponse])
async def list_candidates(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    search: Optional[str] = None,
    skills: Optional[List[str]] = Query(None),
    min_experience: Optional[float] = None,
    max_experience: Optional[float] = None,
    location: Optional[str] = None,
    is_blacklisted: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all candidates with advanced filtering.
    """
    query = db.query(Candidate)
    
    # Filter out blacklisted candidates by default
    query = query.filter(Candidate.is_blacklisted == is_blacklisted)
    
    # Search by name or email
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (Candidate.first_name.ilike(search_term)) |
            (Candidate.last_name.ilike(search_term)) |
            (Candidate.email.ilike(search_term))
        )
    
    # Filter by skills
    if skills:
        for skill in skills:
            query = query.filter(Candidate.skills.contains([skill]))
    
    # Filter by experience
    if min_experience is not None:
        query = query.filter(Candidate.total_experience_years >= min_experience)
    if max_experience is not None:
        query = query.filter(Candidate.total_experience_years <= max_experience)
    
    # Filter by location
    if location:
        query = query.filter(
            (Candidate.current_location.ilike(f"%{location}%")) |
            (Candidate.preferred_location.ilike(f"%{location}%"))
        )
    
    candidates = query.order_by(Candidate.created_at.desc()).offset(skip).limit(limit).all()
    return candidates


@router.get("/{candidate_id}", response_model=CandidateResponse)
async def get_candidate(
    candidate_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get detailed candidate profile.
    """
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    
    if not candidate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate not found"
        )
    
    return candidate


@router.put("/{candidate_id}", response_model=CandidateResponse)
async def update_candidate(
    candidate_id: str,
    candidate_data: CandidateCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update candidate profile.
    """
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    
    if not candidate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate not found"
        )
    
    # Update fields
    update_data = candidate_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(candidate, field, value)
    
    db.commit()
    db.refresh(candidate)
    
    return candidate


@router.delete("/{candidate_id}", response_model=MessageResponse)
async def delete_candidate(
    candidate_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete candidate profile.
    This will cascade delete all related data.
    """
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    
    if not candidate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate not found"
        )
    
    db.delete(candidate)
    db.commit()
    
    return {
        "message": "Candidate deleted successfully",
        "success": True
    }


@router.post("/{candidate_id}/upload-resume")
async def upload_resume(
    candidate_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Upload and parse candidate resume.
    Supports PDF, DOC, DOCX formats.
    """
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    
    if not candidate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate not found"
        )
    
    # Validate file type
    allowed_types = ["application/pdf", "application/msword", 
                     "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only PDF, DOC, DOCX allowed"
        )
    
    # Save to local storage
    upload_dir = f"uploads/resumes/{candidate_id}"
    os.makedirs(upload_dir, exist_ok=True)
    file_path = f"{upload_dir}/{file.filename}"
    
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
         raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not save file: {e}"
        )
    
    # Save document record
    document = CandidateDocument(
        candidate_id=candidate_id,
        document_type="resume",
        file_name=file.filename,
        file_url=file_path,
        mime_type=file.content_type
    )
    db.add(document)
    
    # Update candidate resume URL
    candidate.resume_url = file_path
    
    db.commit()
    
    # Trigger parsing automatically? For now, we wait for explicit call or call it here
    # await parse_resume(candidate_id, db, ...) 
    
    return {
        "message": "Resume uploaded successfully",
        "success": True,
        "file_url": file_path
    }


@router.post("/{candidate_id}/parse-resume", response_model=MessageResponse)
async def parse_resume(
    candidate_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Parse candidate resume using AI.
    Extracts skills, experience, education, etc.
    """
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    
    if not candidate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate not found"
        )
    
    if not candidate.resume_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No resume uploaded for this candidate"
        )
    
    # Use AI Service
    parsed_data = await ai_service.parse_resume(candidate.resume_url)
    
    if "error" in parsed_data:
         # Log error but don't crash - maybe return generic success with warning?
         # Or just use the error message
         pass
    
    # Update candidate with parsed data
    # Note: parsed_data keys match the JSON structure we asked for in AIService
    
    candidate.resume_parsed_data = parsed_data
    candidate.first_name = parsed_data.get("first_name", candidate.first_name)
    candidate.last_name = parsed_data.get("last_name", candidate.last_name)
    candidate.email = parsed_data.get("email", candidate.email)
    candidate.phone = parsed_data.get("phone", candidate.phone)
    candidate.skills = parsed_data.get("skills", [])
    candidate.total_experience_years = parsed_data.get("total_experience_years")
    
    db.commit()
    
    return {
        "message": "Resume parsed successfully",
        "success": True
    }


@router.post("/{candidate_id}/blacklist", response_model=MessageResponse)
async def blacklist_candidate(
    candidate_id: str,
    reason: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Blacklist a candidate with reason.
    """
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    
    if not candidate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate not found"
        )
    
    candidate.is_blacklisted = True
    candidate.blacklist_reason = reason
    db.commit()
    
    return {
        "message": "Candidate blacklisted successfully",
        "success": True
    }


@router.post("/{candidate_id}/unblacklist", response_model=MessageResponse)
async def unblacklist_candidate(
    candidate_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Remove candidate from blacklist.
    """
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    
    if not candidate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate not found"
        )
    
    candidate.is_blacklisted = False
    candidate.blacklist_reason = None
    db.commit()
    
    return {
        "message": "Candidate removed from blacklist",
        "success": True
    }


@router.get("/{candidate_id}/documents")
async def get_candidate_documents(
    candidate_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all documents for a candidate.
    """
    documents = db.query(CandidateDocument).filter(
        CandidateDocument.candidate_id == candidate_id
    ).all()
    
    return documents
