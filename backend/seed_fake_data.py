import os
import sys
import random
from datetime import datetime, timedelta
from faker import Faker
from sqlalchemy.orm import Session
from passlib.context import CryptContext

# Add backend directory to path so we can import modules
sys.path.append(os.path.join(os.path.dirname(__file__)))

from infrastructure.database.connection import SessionLocal, init_db
from infrastructure.database.models import (
    User, JobRequisition, JobPosting, Candidate, Application, 
    Interview, Offer, Employee, JobPostingPlatform, Role, UserRole
)

fake = Faker()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def get_or_create_role(db, role_name):
    role = db.query(Role).filter(Role.name == role_name).first()
    if not role:
        role = Role(name=role_name, description=f"{role_name} role")
        db.add(role)
        db.commit()
        db.refresh(role)
    return role

def seed_data():
    db = SessionLocal()
    try:
        print("Creating Roles...")
        manager_role = get_or_create_role(db, "manager")
        hr_role = get_or_create_role(db, "hr")
        candidate_role = get_or_create_role(db, "candidate")
        admin_role = get_or_create_role(db, "admin")

        print("Creating Users...")
        # Create 5 Managers
        managers = []
        for _ in range(5):
            manager = User(
                email=fake.unique.email(),
                password_hash=get_password_hash("password123"),
                first_name=fake.first_name(),
                last_name=fake.last_name(),
                department=random.choice(["Engineering", "Sales", "Marketing", "HR", "Product"]),
                designation=fake.job(),
                is_active=True,
                is_verified=True
            )
            db.add(manager)
            db.commit() # Need ID for UserRole
            db.refresh(manager)
            
            # Assign Role
            user_role = UserRole(user_id=manager.id, role_id=manager_role.id)
            db.add(user_role)
            managers.append(manager)
        
        # Create 2 HRs
        hrs = []
        for _ in range(2):
            hr = User(
                email=fake.unique.email(),
                password_hash=get_password_hash("password123"),
                first_name=fake.first_name(),
                last_name=fake.last_name(),
                department="HR",
                designation="HR Specialist",
                is_active=True,
                is_verified=True
            )
            db.add(hr)
            db.commit()
            db.refresh(hr)
            
            user_role = UserRole(user_id=hr.id, role_id=hr_role.id)
            db.add(user_role)
            hrs.append(hr)
            
        db.commit()

        print("Creating Job Requisitions...")
        requisitions = []
        for i in range(10):
            req_status = random.choice(["draft", "pending_approval", "approved", "rejected"])
            manager = random.choice(managers)
            req = JobRequisition(
                requisition_number=f"REQ-{datetime.now().year}-{random.randint(1000, 9999)}",
                requested_by=manager.id,
                title=fake.job(),
                department=manager.department or "Engineering",
                employment_type=random.choice(["Full-time", "Contract", "Internship"]),
                job_description=fake.text(max_nb_chars=500),
                experience_min=random.randint(1, 5),
                experience_max=random.randint(6, 12),
                required_skills=[fake.word() for _ in range(random.randint(3, 8))],
                status=req_status,
                priority=random.choice(["low", "medium", "high"]),
                salary_min=random.randint(50000, 80000),
                salary_max=random.randint(85000, 150000),
                currency="USD"
            )
            db.add(req)
            requisitions.append(req)
        db.commit()
        
        for r in requisitions:
            db.refresh(r)

        print("Creating Job Postings...")
        postings = []
        for req in requisitions:
            if req.status == "approved":
                posting = JobPosting(
                    requisition_id=req.id,
                    job_code=f"JOB-{random.randint(1000,9999)}",
                    title=req.title,
                    description=req.job_description,
                    location=fake.city(),
                    employment_type=random.choice(["Full-time", "Contract", "Remote"]),
                    experience_min=req.experience_min,
                    experience_max=req.experience_max,
                    salary_min=req.salary_min,
                    salary_max=req.salary_max,
                    currency=req.currency,
                    skills_required=req.required_skills,
                    is_active=True,
                    published_at=datetime.now() - timedelta(days=random.randint(1, 30)),
                    expires_at=datetime.now() + timedelta(days=random.randint(10, 60))
                )
                db.add(posting)
                postings.append(posting)
        db.commit()
        
        for p in postings:
            db.refresh(p)

        print("Creating Candidates & Applications...")
        for _ in range(20):
            # Create Candidate User (Login)
            cand_user = User(
                email=fake.unique.email(),
                password_hash=get_password_hash("password123"),
                first_name=fake.first_name(),
                last_name=fake.last_name(),
                is_active=True,
                is_verified=True
            )
            db.add(cand_user)
            db.commit()
            db.refresh(cand_user)
            
            user_role = UserRole(user_id=cand_user.id, role_id=candidate_role.id)
            db.add(user_role)
            
            # Create Candidate Profile
            candidate = Candidate(
                first_name=cand_user.first_name,
                last_name=cand_user.last_name,
                email=cand_user.email,
                phone=fake.phone_number(),
                current_location=fake.city(),
                preferred_location=fake.city(),
                total_experience_years=random.uniform(1.0, 15.0),
                current_ctc=random.randint(40000, 120000),
                expected_ctc=random.randint(50000, 150000),
                resume_url="https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                skills=[fake.word() for _ in range(5)],
                created_at=datetime.now() - timedelta(days=random.randint(1, 60))
            )
            db.add(candidate)
            db.commit()
            db.refresh(candidate)
            
            # Apply to random Job Posting
            if postings:
                posting = random.choice(postings)
                app_status = random.choice(["applied", "screening", "interview", "shortlisted", "rejected", "offered", "hired"])
                
                application = Application(
                    application_number=f"APP-{random.randint(10000, 99999)}",
                    job_posting_id=posting.id,
                    candidate_id=candidate.id,
                    status=app_status,
                    source=random.choice(["LinkedIn", "Naukri", "Referral", "Website"]),
                    applied_at=datetime.now() - timedelta(days=random.randint(0, 30)),
                    resume_parsed_data={"education": "B.Tech", "summary": fake.text()}
                )
                db.add(application)
                db.commit()
                db.refresh(application)
                
                # If status is advanced, add interview/offer
                if app_status in ["interview", "offered", "hired"]:
                    interview = Interview(
                        application_id=application.id,
                        candidate_id=candidate.id,
                        interviewer_id=random.choice(managers).id,
                        scheduled_at=datetime.now() + timedelta(days=random.randint(1, 7)),
                        interview_type=random.choice(["Screening", "Technical", "Managerial"]),
                        status="scheduled",
                        meeting_link="https://meet.google.com/abc-defg-hij"
                    )
                    db.add(interview)
                
                if app_status in ["offered", "hired"]:
                    offer = Offer(
                        application_id=application.id,
                        candidate_id=candidate.id,
                        offered_salary=random.randint(int(posting.salary_min or 50000), int(posting.salary_max or 100000)),
                        status="pending" if app_status == "offered" else "accepted",
                        offer_date=datetime.now(),
                        joining_date=datetime.now() + timedelta(days=30)
                    )
                    db.add(offer)

                # If hired, create employee
                if app_status == "hired":
                    emp = Employee(
                        user_id=cand_user.id,
                        candidate_id=candidate.id,
                        employee_id=f"EMP-{random.randint(100,999)}",
                        joined_date=datetime.now().date(),
                        status="active"
                    )
                    db.add(emp)

        
        db.commit()
        print("Seeding completed successfully!")

    except Exception as e:
        print(f"Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()
