from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid
import shutil
import logging

from infrastructure.database.connection import get_db
from infrastructure.database.models import User, BrandingTemplate
from infrastructure.security.auth import get_current_user
from application.schemas import (
    BrandingTemplateResponse,
    MessageResponse,
    BrandingTemplatePreviewRequest,
    LinkedInCustomization,
    LinkedInAssetUploadResponse
)
from application.services.ai_service import AIService
from application.services.linkedin_service import LinkedInService

logger = logging.getLogger(__name__)
router = APIRouter()
linkedin_service = LinkedInService()
ai_service = AIService()

UPLOAD_DIR = os.path.join(os.getcwd(), "uploads", "templates")
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload", response_model=BrandingTemplateResponse)
async def upload_template(
    name: str = Form(...),
    template_type: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Admin only: Upload a background image template.
    """
    # TODO: Check if user is admin
    
    # Save file
    file_ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Store in DB
    new_template = BrandingTemplate(
        name=name,
        template_type=template_type.upper(),
        file_path=file_path,
        is_active=True
    )
    
    db.add(new_template)
    db.commit()
    db.refresh(new_template)
    
    # Generate an initial preview automatically to "Check the sample"
    preview_url = None
    try:
        output_path = await linkedin_service.generate_branded_image(
            title="Sample Creative Role",
            template_path=file_path,
            highlights=["AI Style Analysis", "Dynamic Color Matching", "Premium Design"],
            template_type=template_type.upper(),
            preview_mode=True
        )
        if output_path:
            preview_url = f"/uploads/generated_posts/{os.path.basename(output_path)}"
    except Exception as e:
        logger.error(f"Initial preview generation failed: {e}")

    return {
        "id": str(new_template.id),
        "name": new_template.name,
        "template_type": new_template.template_type,
        "preview_url": preview_url,
        "message": "Template uploaded and analyzed successfully"
    }

@router.get("/", response_model=List[BrandingTemplateResponse])
async def list_templates(
    template_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List available branding templates.
    """
    query = db.query(BrandingTemplate).filter(BrandingTemplate.is_active == True)
    if template_type:
        query = query.filter(BrandingTemplate.template_type == template_type.upper())
    
    return query.all()

@router.post("/{template_id}/preview")
async def get_template_preview(
    template_id: str,
    preview_data: BrandingTemplatePreviewRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate a sample image using the template and dummy data.
    Returns the URL of the generated image.
    """
    template = db.query(BrandingTemplate).filter(BrandingTemplate.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
        
    try:
        # Use a specialized mock path for preview or reuse the generate_branded_image logic
        # For now, let's assume we update LinkedInService to handle this.
        
        # We need to find or create a temp directory for previews
        preview_dir = os.path.join(os.getcwd(), "uploads", "previews")
        os.makedirs(preview_dir, exist_ok=True)
        
        # Generate the image
        # This will be implemented in LinkedInService
        output_path = await linkedin_service.generate_branded_image(
            title=preview_data.title,
            template_path=template.file_path,
            highlights=preview_data.highlights,
            template_type=template.template_type,
            candidate_name=preview_data.candidate_name,
            preview_mode=True
        )
        
        if not output_path:
            raise HTTPException(status_code=500, detail="Failed to generate preview")
            
        # Return relative URL
        return {"preview_url": f"/uploads/generated_posts/{os.path.basename(output_path)}"}
        
    except Exception as e:
        logger.error(f"Preview generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Preview generation failed: {str(e) or type(e).__name__}")

@router.post("/{template_id}/ai-preview")
async def get_template_ai_preview(
    template_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate a sample image using AI to create realistic dummy content.
    """
    template = db.query(BrandingTemplate).filter(BrandingTemplate.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
        
    try:
        # 1. Generate AI content
        ai_data = await ai_service.generate_sample_post_data(template.template_type)
        
        # 2. Generate the image
        output_path = await linkedin_service.generate_branded_image(
            title=ai_data.get("title", "Sample Role"),
            template_path=template.file_path,
            highlights=ai_data.get("highlights", []),
            template_type=template.template_type,
            candidate_name=ai_data.get("candidate_name", "Sample Candidate"),
            preview_mode=True
        )
        
        if not output_path:
            raise HTTPException(status_code=500, detail="Failed to generate AI preview")
            
        return {
            "preview_url": f"/uploads/generated_posts/{os.path.basename(output_path)}",
            "ai_content": ai_data
        }
        
    except Exception as e:
        logger.error(f"AI Preview generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"AI Preview generation failed: {str(e) or type(e).__name__}")

@router.delete("/{template_id}", response_model=MessageResponse)
async def delete_template(
    template_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a branding template (soft delete).
    """
    template = db.query(BrandingTemplate).filter(BrandingTemplate.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
        
    template.is_active = False
    db.commit()
    
    return {"message": "Template deleted successfully", "success": True}

@router.post("/assets", response_model=LinkedInAssetUploadResponse)
async def upload_branding_asset(
    asset_type: str = Form(...), # logo or background
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Upload a branding asset (logo or background)."""
    logger.info(f"Uploading branding asset: {asset_type} | filename: {file.filename}")
    asset_dir = os.path.join(os.getcwd(), "uploads", "branding")
    if not os.path.exists(asset_dir):
        os.makedirs(asset_dir, exist_ok=True)
    
    file_ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{asset_type}_{uuid.uuid4()}{file_ext}"
    file_path = os.path.join(asset_dir, unique_filename)
    
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        logger.info(f"Asset saved successfully at: {file_path}")
    except Exception as e:
        logger.error(f"Failed to save asset: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save asset: {str(e)}")
        
    url = f"/uploads/branding/{unique_filename}"
    return {"url": url, "asset_type": asset_type, "success": True}

@router.get("/linkedin-theme", response_model=LinkedInCustomization)
async def get_linkedin_theme(
    current_user: User = Depends(get_current_user)
):
    """
    Get saved LinkedIn company theme settings.
    """
    return await linkedin_service.get_theme()

@router.post("/linkedin-theme", response_model=MessageResponse)
async def update_linkedin_theme(
    theme_data: LinkedInCustomization,
    current_user: User = Depends(get_current_user)
):
    """
    Update LinkedIn company theme settings.
    """
    await linkedin_service.save_theme(
        primary_color=theme_data.primary_color,
        accent_color=theme_data.accent_color,
        logo_url=theme_data.logo_url,
        background_url=theme_data.background_url,
        company_name=theme_data.company_name
    )
    return {"message": "LinkedIn theme updated successfully", "success": True}
