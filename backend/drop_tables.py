from infrastructure.database.connection import engine
from sqlalchemy import text

tables = [
    "audit_logs", "onboarding_tasks", "referrals", "interview_feedback", 
    "interview_panel", "interviews", "offers", "offer_approvals", 
    "applications", "candidate_documents", "candidates", "job_posting_platforms", 
    "job_postings", "job_requisition_approvals", "job_requisitions", "employees", 
    "user_roles", "role_permissions", "permissions", "roles", "users", 
    "configurations", "notification_templates", "interview_questions", 
    "data_retention_policies", "candidate_sources"
]

def drop_all():
    print("Force dropping all known tables...")
    with engine.connect() as conn:
        for table in tables:
            print(f"Dropping {table}...")
            conn.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))
        conn.commit()
    print("✓ All tables dropped.")

if __name__ == "__main__":
    drop_all()
