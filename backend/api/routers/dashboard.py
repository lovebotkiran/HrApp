from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from infrastructure.database.connection import get_db
from infrastructure.database.models import Application, User
from infrastructure.security.auth import get_current_user
from application.schemas import RecruitmentPipelineStats, RecruitmentMetrics

router = APIRouter()


@router.get("/pipeline", response_model=RecruitmentPipelineStats)
async def get_pipeline_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get recruitment pipeline statistics."""
    stats = {
        "applied": db.query(Application).filter(Application.status == "applied").count(),
        "screening": db.query(Application).filter(Application.status == "screening").count(),
        "shortlisted": db.query(Application).filter(Application.status == "shortlisted").count(),
        "interview": db.query(Application).filter(Application.status == "interview").count(),
        "selected": db.query(Application).filter(Application.status == "selected").count(),
        "offered": db.query(Application).filter(Application.status == "offered").count(),
        "onboarded": 0  # TODO: Count from onboarding table
    }
    return stats


@router.get("/metrics", response_model=RecruitmentMetrics)
async def get_recruitment_metrics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get overall recruitment metrics."""
    total_applications = db.query(Application).count()
    total_hires = db.query(Application).filter(Application.status == "offered").count()
    
    return {
        "total_applications": total_applications,
        "total_hires": total_hires,
        "average_time_to_hire_days": None,  # TODO: Calculate
        "average_cost_per_hire": None,  # TODO: Calculate
        "offer_acceptance_rate": None,  # TODO: Calculate
        "source_effectiveness": {}  # TODO: Calculate by source
    }
