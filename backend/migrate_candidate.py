
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

load_dotenv()

db_url = os.getenv("DATABASE_URL")

engine = create_engine(db_url)

with engine.connect() as conn:
    print("Adding is_active column to candidates table...")
    try:
        conn.execute(text("ALTER TABLE candidates ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;"))
        conn.commit()
        print("Column added successfully!")
    except Exception as e:
        print(f"Error: {e}")
