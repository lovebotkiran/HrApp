from passlib.context import CryptContext
pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
h = pwd_context.hash('Admin@123')
print(f'HASH:{h}')
print(f'VERIFY:{pwd_context.verify("Admin@123", h)}')
