from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import uuid

from infrastructure.database.connection import get_db
# from infrastructure.database.models import Employee, OnboardingTask
from infrastructure.security.auth import get_current_user
from application.schemas import MessageResponse

router = APIRouter()

@router.get("/")
async def list_onboarding_tasks():
    return {"message": "Onboarding module placeholder"}
