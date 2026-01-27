from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import uuid

from infrastructure.database.connection import get_db
from infrastructure.database.models import (
    Offer, OfferApproval,
    Application, Candidate, JobPosting, User
)
from infrastructure.security.auth import get_current_user
from application.schemas import (
    OfferCreate,
    OfferResponse,
    OfferApprovalRequest,
    OfferAcceptanceRequest,
    MessageResponse
)
from application.services.document_service import DocumentService

router = APIRouter()


@router.post("/", response_model=OfferResponse, status_code=status.HTTP_201_CREATED)
async def create_offer(
    offer_data: OfferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new job offer.
    """
    # Verify application exists
    application = db.query(Application).filter(
        Application.id == offer_data.application_id
    ).first()
    
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found"
        )
    
    # Check if offer already exists for this application
    existing_offer = db.query(Offer).filter(
        Offer.application_id == offer_data.application_id,
        Offer.status.in_(["draft", "pending_approval", "approved", "sent", "accepted"])
    ).first()
    
    if existing_offer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Active offer already exists for this application"
        )
    
    # Generate offer number
    offer_number = f"OFF-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
    
    # Create offer
    new_offer = Offer(
        offer_number=offer_number,
        **offer_data.dict()
    )
    
    db.add(new_offer)
    db.flush()
    
    # Create approval workflow
    # Level 1: HR, Level 2: Finance, Level 3: Director
    approval_levels = [
        {"level": 1, "role": "HR"},
        {"level": 2, "role": "Finance"},
        {"level": 3, "role": "Director"}
    ]
    
    for level_info in approval_levels:
        approval = OfferApproval(
            offer_id=new_offer.id,
            approval_level=level_info["level"],
            status="pending"
        )
        db.add(approval)
    
    db.commit()
    db.refresh(new_offer)
    
    return new_offer


@router.get("/", response_model=List[OfferResponse])
async def list_offers(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    status: Optional[str] = None,
    candidate_id: Optional[str] = None,
    job_posting_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all offers with filtering.
    """
    query = db.query(Offer)
    
    # Apply filters
    if status:
        query = query.filter(Offer.status == status)
    if candidate_id:
        query = query.filter(Offer.candidate_id == candidate_id)
    if job_posting_id:
        query = query.filter(Offer.job_posting_id == job_posting_id)
    
    offers = query.order_by(Offer.created_at.desc()).offset(skip).limit(limit).all()
    return offers


@router.get("/{offer_id}", response_model=OfferResponse)
async def get_offer(
    offer_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get offer details.
    """
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    return offer


@router.put("/{offer_id}", response_model=OfferResponse)
async def update_offer(
    offer_id: str,
    offer_data: OfferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update offer details.
    Can only update offers in draft status.
    """
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    if offer.status not in ["draft", "pending_approval"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only update offers in draft or pending approval status"
        )
    
    # Update fields
    update_data = offer_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(offer, field, value)
    
    db.commit()
    db.refresh(offer)
    
    return offer


@router.post("/{offer_id}/approve", response_model=MessageResponse)
async def approve_offer(
    offer_id: str,
    approval_data: OfferApprovalRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Approve or reject an offer.
    """
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    # Find pending approval for current user
    approval = db.query(OfferApproval).filter(
        OfferApproval.offer_id == offer_id,
        OfferApproval.status == "pending"
    ).order_by(OfferApproval.approval_level).first()
    
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
    
    # Update offer status
    if approval_data.status == "rejected":
        offer.status = "rejected"
    elif approval_data.status == "approved":
        # Check if all approvals are complete
        pending_approvals = db.query(OfferApproval).filter(
            OfferApproval.offer_id == offer_id,
            OfferApproval.status == "pending"
        ).count()
        
        if pending_approvals == 0:
            offer.status = "approved"
        else:
            offer.status = "pending_approval"
    
    db.commit()
    
    return {
        "message": f"Offer {approval_data.status} successfully",
        "success": True
    }


@router.post("/{offer_id}/send", response_model=MessageResponse)
async def send_offer(
    offer_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Send offer to candidate.
    Offer must be approved first.
    """
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    if offer.status != "approved":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only send approved offers"
        )
    
    offer.status = "sent"
    offer.sent_at = datetime.utcnow()
    
    # Update application status
    application = db.query(Application).filter(
        Application.id == offer.application_id
    ).first()
    if application:
        application.status = "offered"
    
    db.commit()
    
    # TODO: Send offer letter email to candidate
    # TODO: Generate offer letter PDF
    
    return {
        "message": "Offer sent to candidate successfully",
        "success": True
    }


@router.post("/{offer_id}/accept", response_model=MessageResponse)
async def accept_offer(
    offer_id: str,
    acceptance_data: OfferAcceptanceRequest,
    db: Session = Depends(get_db)
):
    """
    Candidate accepts or rejects offer.
    Public endpoint (no authentication required).
    """
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    if offer.status != "sent":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Offer is not in sent status"
        )
    
    # Check if offer has expired
    if offer.offer_valid_until < datetime.utcnow().date():
        offer.status = "expired"
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Offer has expired"
        )
    
    if acceptance_data.accepted:
        offer.status = "accepted"
        offer.accepted_at = datetime.utcnow()
        
        # TODO: Save digital signature
        # TODO: Initiate onboarding process
        
        message = "Offer accepted successfully"
    else:
        offer.status = "rejected"
        offer.rejected_at = datetime.utcnow()
        offer.rejection_reason = acceptance_data.rejection_reason
        
        message = "Offer rejected"
    
    db.commit()
    
    return {
        "message": message,
        "success": True
    }


@router.post("/{offer_id}/revise", response_model=OfferResponse)
async def revise_offer(
    offer_id: str,
    offer_data: OfferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a revised offer.
    """
    original_offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not original_offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    # Mark original offer as withdrawn
    original_offer.status = "withdrawn"
    
    # Create new revised offer
    offer_number = f"OFF-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}-REV"
    
    revised_offer = Offer(
        offer_number=offer_number,
        **offer_data.dict()
    )
    
    db.add(revised_offer)
    db.commit()
    db.refresh(revised_offer)
    
    return revised_offer


@router.post("/{offer_id}/withdraw", response_model=MessageResponse)
async def withdraw_offer(
    offer_id: str,
    reason: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Withdraw an offer.
    """
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    if offer.status == "accepted":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot withdraw accepted offer"
        )
    
    offer.status = "withdrawn"
    offer.rejection_reason = reason
    
    db.commit()
    
    return {
        "message": "Offer withdrawn successfully",
        "success": True
    }


@router.get("/{offer_id}/approvals")
async def get_offer_approvals(
    offer_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all approvals for an offer.
    """
    approvals = db.query(OfferApproval).filter(
        OfferApproval.offer_id == offer_id
    ).order_by(OfferApproval.approval_level).all()
    
    return approvals


@router.post("/{offer_id}/generate-documents", response_model=MessageResponse)
async def generate_offer_documents(
    offer_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate offer letter and NDA documents.
    """
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found"
        )
    
    candidate = db.query(Candidate).filter(Candidate.id == offer.candidate_id).first()
    job_posting = db.query(JobPosting).filter(JobPosting.id == offer.job_posting_id).first()
    
    if not candidate or not job_posting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Candidate or Job Posting not found for this offer"
        )

    doc_service = DocumentService()
    
    try:
        # Generate Offer Letter
        offer_data = doc_service.get_offer_letter_data(offer, candidate, job_posting)
        offer_filename = f"Offer_Letter_{candidate.first_name}_{candidate.last_name}_{offer.offer_number}.docx"
        offer_path = doc_service.generate_document("offer_letter_template.docx", offer_data, offer_filename)
        
        # Generate NDA
        nda_data = doc_service.get_nda_data(offer, candidate, job_posting)
        nda_filename = f"NDA_{candidate.first_name}_{candidate.last_name}_{offer.offer_number}.docx"
        nda_path = doc_service.generate_document("nda_template.docx", nda_data, nda_filename)
        
        # Update offer with document URLs
        # Assuming we store them as a comma-separated list or in a JSON field if available
        # But looking at the model, there's only offer_letter_url.
        # Let's use that for the offer letter and maybe add a documents field later.
        offer.offer_letter_url = f"/uploads/documents/{offer_filename}"
        # We can store the NDA in a similar way if we had a field, for now just offer_letter_url
        
        db.commit()
        
        return {
            "message": "Documents generated successfully",
            "success": True,
            "url": offer.offer_letter_url
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating documents: {str(e)}"
        )


@router.post("/{offer_id}/generate-letter", response_model=MessageResponse)
async def generate_offer_letter(
    offer_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Deprecated: Use generate-documents instead.
    """
    return await generate_offer_documents(offer_id, db, current_user)
