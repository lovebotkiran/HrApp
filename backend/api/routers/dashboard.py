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
    from infrastructure.database.models import Employee
    
    stats = {
        "applied": db.query(Application).filter(Application.status == "applied").count(),
        "screening": db.query(Application).filter(Application.status == "screening").count(),
        "shortlisted": db.query(Application).filter(Application.status == "shortlisted").count(),
        "interview": db.query(Application).filter(Application.status == "interview").count(),
        "selected": db.query(Application).filter(Application.status == "selected").count(),
        "offered": db.query(Application).filter(Application.status == "offered").count(),
        "onboarded": db.query(Employee).count()
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
    
    # Calculate average time to hire (applied_at to offered/accepted)
    # This is a simplified version
    avg_time_query = db.query(
        func.avg(
            func.extract('day', Application.updated_at - Application.applied_at)
        )
    ).filter(Application.status == "offered").scalar()
    
    # Calculate offer acceptance rate
    total_offered = db.query(Application).filter(Application.status == "offered").count()
    total_accepted = db.query(Application).filter(Application.status == "selected").count() # Assuming selected means hire
    # Better: check Offers table if it exists
    from infrastructure.database.models import Offer
    total_offers_sent = db.query(Offer).filter(Offer.status == "sent").count()
    total_offers_accepted = db.query(Offer).filter(Offer.status == "accepted").count()
    
    acceptance_rate = (total_offers_accepted / total_offers_sent * 100) if total_offers_sent > 0 else 0
    
    # Source effectiveness
    sources = db.query(
        Application.source, 
        func.count(Application.id)
    ).group_by(Application.source).all()
    
    source_stats = {source: count for source, count in sources}
    
    return {
        "total_applications": total_applications,
        "total_hires": total_hires,
        "average_time_to_hire_days": round(avg_time_query, 2) if avg_time_query else 0,
        "average_cost_per_hire": 0,  # Still placeholder as cost data isn't in models yet
        "offer_acceptance_rate": round(acceptance_rate, 2),
        "source_effectiveness": source_stats
    }
