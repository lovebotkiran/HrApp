from infrastructure.database.connection import init_db
from infrastructure.database.models import *

print("Initializing new database tables...")
try:
    init_db()
    print("Database tables created successfully!")
except Exception as e:
    print(f"Error creating tables: {e}")
