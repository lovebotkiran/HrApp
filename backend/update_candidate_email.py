import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from infrastructure.database.connection import SessionLocal
from infrastructure.database.models import Candidate

# Update email address
old_email = "ssughumar@gmail.com"
new_email = "stephankestroy@gmail.com"

print("=" * 60)
print("UPDATING CANDIDATE EMAIL ADDRESS")
print("=" * 60)

db = SessionLocal()

try:
    # Find candidate by old email
    candidate = db.query(Candidate).filter(Candidate.email == old_email).first()
    
    if candidate:
        print(f"Found candidate: {candidate.first_name} {candidate.last_name}")
        print(f"Current email: {candidate.email}")
        
        # Update email
        candidate.email = new_email
        db.commit()
        
        print(f"✓ Updated email to: {new_email}")
        print()
        print("=" * 60)
        print("EMAIL UPDATED SUCCESSFULLY!")
        print("=" * 60)
        print(f"Interview invitations will now be sent to: {new_email}")
    else:
        print(f"Candidate not found with email: {old_email}")
        print("Checking if candidate exists with new email...")
        
        candidate = db.query(Candidate).filter(Candidate.email == new_email).first()
        if candidate:
            print(f"✓ Candidate already has email: {new_email}")
        else:
            print("No candidate found. Please create the candidate first.")

except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
