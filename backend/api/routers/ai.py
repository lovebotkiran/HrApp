from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import logging
from application.services.ai_service import AIService

router = APIRouter()
logger = logging.getLogger(__name__)
ai_service = AIService()


class GenerateJobDescriptionRequest(BaseModel):
    title: str
    department: str
    skills: List[str]
    experience: Optional[int] = 0
    employment_type: Optional[str] = "Full-time"


class GenerateJobDescriptionResponse(BaseModel):
    description: str


@router.post("/generate-job-description", response_model=GenerateJobDescriptionResponse)
async def generate_job_description(request: GenerateJobDescriptionRequest):
    """
    Generate a job description using AI based on the provided details.
    Uses local AI Service (Ollama).
    """
    try:
        description = await ai_service.generate_jd(
            title=request.title,
            skills=request.skills,
            experience_min=request.experience,
            experience_max=request.experience + 2 if request.experience else 3
        )
        
        return GenerateJobDescriptionResponse(description=description)

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred: {str(e)}"
        )

