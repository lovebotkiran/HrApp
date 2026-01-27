import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from infrastructure.database.connection import SessionLocal
from infrastructure.database.models import Candidate, Application, JobPosting
from datetime import datetime
import uuid

# Candidate details from PDF
email = "ssughumar@gmail.com"
first_name = "Stephan"
last_name = "Kestroy"
phone = "+94 70 2036472"

print("=" * 60)
print("SETTING UP SHORTLISTED CANDIDATE FOR INTERVIEW")
print("=" * 60)
print(f"Name: {first_name} {last_name}")
print(f"Email: {email}")
print(f"Phone: {phone}")
print()

db = SessionLocal()

try:
    # Check if candidate exists
    candidate = db.query(Candidate).filter(Candidate.email == email).first()
    
    if not candidate:
        print("Candidate not found. Creating new candidate...")
        candidate = Candidate(
            email=email,
            first_name=first_name,
            last_name=last_name,
            phone=phone,
            resume_url="/uploads/resumes/a6f14f7f-4627-4d5a-b724-d0c60884c2c1/Stephan Kestroy.pdf"
        )
        db.add(candidate)
        db.commit()
        db.refresh(candidate)
        print(f"SUCCESS: Created candidate with ID: {candidate.id}")
    else:
        print(f"SUCCESS: Found existing candidate with ID: {candidate.id}")
    
    print()
    
    # Check for existing applications
    applications = db.query(Application).filter(
        Application.candidate_id == candidate.id
    ).all()
    
    if applications:
        print(f"Found {len(applications)} existing application(s)")
        for app in applications:
            job = db.query(JobPosting).filter(JobPosting.id == app.job_posting_id).first()
            print(f"  - Application {app.application_number}")
            print(f"    Job: {job.title if job else 'Unknown'}")
            print(f"    Current Status: {app.status}")
            
            if app.status != 'shortlisted':
                app.status = 'shortlisted'
                db.commit()
                print(f"    ACTION: Updated to 'shortlisted'")
            print()
    else:
        print("No existing applications found. Creating new application...")
        
        # Get first active job posting
        job_posting = db.query(JobPosting).filter(JobPosting.is_active == True).first()
        
        if not job_posting:
            print("ERROR: No active job postings found!")
            print("Please create a job posting first.")
        else:
            app_number = f"APP-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
            
            new_app = Application(
                application_number=app_number,
                job_posting_id=job_posting.id,
                candidate_id=candidate.id,
                source="manual",
                status="shortlisted"
            )
            db.add(new_app)
            db.commit()
            db.refresh(new_app)
            
            print(f"SUCCESS: Created application {new_app.application_number}")
            print(f"  Job: {job_posting.title}")
            print(f"  Status: {new_app.status}")
            print()
    
    print("=" * 60)
    print("READY FOR INTERVIEW SCHEDULING!")
    print("=" * 60)
    print(f"Candidate ID: {candidate.id}")
    print(f"Navigate to 'Shortlisted Candidates' screen to schedule interview")
    print()

except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
