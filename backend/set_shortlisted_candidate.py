import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from infrastructure.database.connection import SessionLocal
from infrastructure.database.models import Candidate, Application, JobPosting
import pdfplumber

# Extract email from PDF
pdf_path = r'uploads/resumes/a6f14f7f-4627-4d5a-b724-d0c60884c2c1/Stephan Kestroy.pdf'
pdf = pdfplumber.open(pdf_path)
text = ''.join([page.extract_text() for page in pdf.pages])
pdf.close()

# Parse email from text
email = "ssughumar@gmail.com"  # Found in the PDF
name = "Stephan Kestroy"

print(f"Found candidate: {name}")
print(f"Email: {email}")

# Connect to database
db = SessionLocal()

try:
    # Find candidate by email
    candidate = db.query(Candidate).filter(Candidate.email == email).first()
    
    if not candidate:
        print(f"\nCandidate not found with email {email}")
        print("Searching by name...")
        candidate = db.query(Candidate).filter(
            Candidate.first_name.ilike('%stephan%')
        ).first()
    
    if candidate:
        print(f"\nFound candidate: {candidate.first_name} {candidate.last_name}")
        print(f"Candidate ID: {candidate.id}")
        
        # Find their applications
        applications = db.query(Application).filter(
            Application.candidate_id == candidate.id
        ).all()
        
        print(f"\nFound {len(applications)} application(s)")
        
        for app in applications:
            job_posting = db.query(JobPosting).filter(
                JobPosting.id == app.job_posting_id
            ).first()
            
            print(f"\nApplication ID: {app.id}")
            print(f"Current Status: {app.status}")
            print(f"Job: {job_posting.title if job_posting else 'Unknown'}")
            
            # Update to shortlisted
            if app.status not in ['shortlisted', 'interview', 'selected', 'offered']:
                app.status = 'shortlisted'
                db.commit()
                print(f"✓ Updated status to: shortlisted")
            else:
                print(f"Already in status: {app.status}")
        
        print(f"\n✓ Candidate is now ready for interview scheduling!")
        
    else:
        print(f"\nCandidate not found in database. Creating new candidate...")
        
        # Create new candidate
        new_candidate = Candidate(
            email=email,
            first_name="Stephan",
            last_name="Kestroy",
            phone="+94 70 2036472",
            resume_url=f"/uploads/resumes/a6f14f7f-4627-4d5a-b724-d0c60884c2c1/Stephan Kestroy.pdf"
        )
        db.add(new_candidate)
        db.commit()
        db.refresh(new_candidate)
        
        print(f"✓ Created candidate: {new_candidate.first_name} {new_candidate.last_name}")
        print(f"Candidate ID: {new_candidate.id}")
        
        # Find an active job posting to create application
        job_posting = db.query(JobPosting).filter(
            JobPosting.is_active == True
        ).first()
        
        if job_posting:
            # Create application
            from datetime import datetime
            import uuid
            
            app_number = f"APP-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
            
            new_application = Application(
                application_number=app_number,
                job_posting_id=job_posting.id,
                candidate_id=new_candidate.id,
                source="manual",
                status="shortlisted"
            )
            db.add(new_application)
            db.commit()
            db.refresh(new_application)
            
            print(f"\n✓ Created application for: {job_posting.title}")
            print(f"Application ID: {new_application.id}")
            print(f"Status: {new_application.status}")
            print(f"\n✓ Candidate is now ready for interview scheduling!")
        else:
            print("\nNo active job postings found. Please create a job posting first.")

except Exception as e:
    print(f"\nError: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
