from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

# Database connection
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/agentichr"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def approve_requisition():
    db = SessionLocal()
    try:
        # Update requisition status
        db.execute(text("UPDATE job_requisitions SET status = 'approved' WHERE id = 'b48eda63-cf2a-4343-b85c-82134a60013c'"))
        
        # Update all approvals to approved
        db.execute(text("UPDATE job_requisition_approvals SET status = 'approved', approved_at = NOW() WHERE requisition_id = 'b48eda63-cf2a-4343-b85c-82134a60013c'"))
        
        db.commit()
        print("Requisition approved successfully")
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    approve_requisition()
