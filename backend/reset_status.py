import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from sqlalchemy import text
from infrastructure.database.connection import SessionLocal
from infrastructure.database.models import Candidate, Application, Interview

# Candidate email
email = "stephankestroy@gmail.com"

print("=" * 60)
print("RESETTING APPLICATION STATUS TO 'SHORTLISTED'")
print("=" * 60)

db = SessionLocal()

try:
    # Find candidate
    candidate = db.query(Candidate).filter(Candidate.email == email).first()
    
    if candidate:
        print(f"Found candidate: {candidate.first_name} {candidate.last_name}")
        
        # Find applications
        applications = db.query(Application).filter(
            Application.candidate_id == candidate.id
        ).all()
        
        if applications:
            for app in applications:
                print(f"Application {app.application_number} status: {app.status}")
                
                # Force reset
                app.status = 'shortlisted'
                
                # Delete ALL scheduled interviews for this app to allow rescheduling
                interviews = db.query(Interview).filter(
                    Interview.application_id == app.id
                ).all()
                
                for interview in interviews:
                    print(f"  - Deleting interview record: {interview.id} ({interview.status})")
                    # Also delete panel members using SQL directly to avoid ORM issues
                    try:
                        db.execute(text("DELETE FROM interview_panel WHERE interview_id = :id"), {"id": str(interview.id)})
                    except Exception as e:
                        print(f"Error deleting panel: {e}")
                    
                    db.delete(interview)
                
                db.commit()
                print(f"✓ FORCED Reset status to: shortlisted")
        else:
            print("No applications found for this candidate.")
    else:
        print(f"Candidate not found with email: {email}")

except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
    print("=" * 60)
