import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from infrastructure.database.connection import SessionLocal
from infrastructure.database.models import User, UserRole, Role
from infrastructure.security.auth import get_password_hash
import uuid

# Interviewer Details
EMAIL = "kirankiruthigan@gmail.com"
FIRST_NAME = "Interviewer1"
LAST_NAME = "AgenticHR"
PASSWORD = "Password@123"  # Dummy password
INTERVIEWER_ROLE_ID = "55555555-5555-5555-5555-555555555555"

print("=" * 60)
print("SEEDING INTERVIEWER USER")
print("=" * 60)

db = SessionLocal()

try:
    # 1. Check if user exists
    user = db.query(User).filter(User.email == EMAIL).first()
    
    if user:
        print(f"User {EMAIL} already exists.")
        print(f"User ID: {user.id}")
    else:
        print(f"Creating new interviewer: {EMAIL}")
        password_hash = get_password_hash(PASSWORD)
        
        user = User(
            id=uuid.uuid4(),
            email=EMAIL,
            password_hash=password_hash,
            first_name=FIRST_NAME,
            last_name=LAST_NAME,
            department="Engineering",
            designation="Senior Engineer",
            phone="+919876543210",
            is_active=True,
            is_verified=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"✓ Created user with ID: {user.id}")

    # 2. Check Role Assignment
    user_role = db.query(UserRole).filter(
        UserRole.user_id == user.id,
        UserRole.role_id == INTERVIEWER_ROLE_ID
    ).first()
    
    if user_role:
        print("✓ User already has 'Interviewer' role.")
    else:
        print("Assigning 'Interviewer' role...")
        new_role = UserRole(
            id=uuid.uuid4(),
            user_id=user.id,
            role_id=INTERVIEWER_ROLE_ID
        )
        db.add(new_role)
        db.commit()
        print("✓ Assigned role successfully.")

except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
    print("=" * 60)
