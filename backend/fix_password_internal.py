from infrastructure.database.connection import SessionLocal
from infrastructure.database.models import User
from passlib.context import CryptContext

db = SessionLocal()
user = db.query(User).filter(User.email == 'admin@agentichr.com').first()

if user:
    pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
    new_hash = pwd_context.hash('Admin@123')
    print(f"Generated Hash: {new_hash}")
    
    user.password_hash = new_hash
    db.commit()
    print("Password updated successfully via ORM.")
else:
    print("User not found.")
db.close()
