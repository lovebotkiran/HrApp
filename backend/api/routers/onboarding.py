from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import uuid
from datetime import datetime
from infrastructure.database.connection import get_db
from infrastructure.database.models import Employee, Candidate, Application, User
from infrastructure.security.auth import get_current_user
from application.schemas import MessageResponse

# Logger
import logging
logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/")
async def list_onboarding_employees(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List all employees in onboarding status."""
    employees = db.query(Employee).all()
    return employees

@router.get("/{candidate_id}/status")
async def get_onboarding_status(
    candidate_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get onboarding status for a specific candidate."""
    employee = db.query(Employee).filter(Employee.candidate_id == candidate_id).first()
    if not employee:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Onboarding record not found for this candidate"
        )
    return employee

@router.post("/{application_id}/initiate")
async def initiate_onboarding(
    application_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Initiate onboarding for a hired candidate."""
    application = db.query(Application).filter(Application.id == application_id).first()
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")
    
    if application.status != "offered":
        raise HTTPException(status_code=400, detail="Can only initiate onboarding for offered/accepted candidates")
    
    # Check if already exists
    existing = db.query(Employee).filter(Employee.candidate_id == application.candidate_id).first()
    if existing:
         return {"message": "Onboarding already initiated", "employee_id": existing.employee_id}
         
    # Create new employee record
    temp_emp_id = f"EMP-{uuid.uuid4().hex[:8].upper()}"
    new_employee = Employee(
        candidate_id=application.candidate_id,
        employee_id=temp_emp_id,
        joined_date=datetime.utcnow().date(),
        status="onboarding"
    )
    db.add(new_employee)
    db.commit()
    
    return {"message": "Onboarding initiated", "employee_id": temp_emp_id}
