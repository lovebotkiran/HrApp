from infrastructure.database.connection import engine, Base
import infrastructure.database.models # Import all models

# Create all tables known to Base.metadata
print("Creating all tables from models...")
Base.metadata.create_all(bind=engine)
print("✓ All tables created successfully.")
