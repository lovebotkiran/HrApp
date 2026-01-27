import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from infrastructure.database.connection import SessionLocal
from infrastructure.database.models import Candidate, Application, JobPosting
import uuid
from datetime import datetime

# details
RESUME_PATH = "backend/uploads/resumes/a6f14f7f-4627-4d5a-b724-d0c60884c2c1/Stephan Kestroy.pdf"
candidate_data = {
    "first_name": "Stephan",
    "last_name": "Kestroy",
    "email": "stephankestroy@gmail.com",
    "phone": "+91 98765 43210",
    "job_title": "Software Engineer" # We'll match this or just pick first job
}

print("=" * 60)
print("APPLYING CANDIDATE & SHORTLISTING")
print("=" * 60)

db = SessionLocal()

try:
    # 1. Get Job Posting
    job = db.query(JobPosting).filter(JobPosting.is_active == True).first()
    if not job:
        print("No active job postings found. Cannot apply.")
        sys.exit(1)
    
    print(f"Applying for Job: {job.title} ({job.job_code})")

    # 2. Create/Get Candidate
    candidate = db.query(Candidate).filter(Candidate.email == candidate_data["email"]).first()
    if not candidate:
        print("Creating new candidate...")
        candidate = Candidate(
            id=uuid.uuid4(),
            email=candidate_data["email"],
            first_name=candidate_data["first_name"],
            last_name=candidate_data["last_name"],
            phone=candidate_data["phone"],
            resume_url=RESUME_PATH,
            current_designation="Developer"
        )
        db.add(candidate)
        db.commit()
        db.refresh(candidate)
        print(f"✓ Created Candidate: {candidate.id}")
    else:
        print(f"Found existing candidate: {candidate.id}")
        candidate.resume_url = RESUME_PATH
        db.commit()

    # 3. Create Application
    # Check if exists
    application = db.query(Application).filter(
        Application.candidate_id == candidate.id,
        Application.job_posting_id == job.id
    ).first()

    if application:
        print(f"Application exists. Status: {application.status}")
        application.status = "shortlisted"
        # Delete interviews if any (cleanup)
        db.execute("DELETE FROM interview_panel WHERE interview_id IN (SELECT id FROM interviews WHERE application_id = :aid)", {"aid": application.id})
        db.execute("DELETE FROM interviews WHERE application_id = :aid", {"aid": application.id})
    else:
        print("Creating new application...")
        application = Application(
            id=uuid.uuid4(),
            application_number=f"APP-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}",
            job_posting_id=job.id,
            candidate_id=candidate.id,
            status="shortlisted",
            source="manual",
            applied_at=datetime.now()
        )
        db.add(application)
    
    db.commit()
    print(f"✓ Application saved with status: SHORTLISTED")

except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
    print("=" * 60)
