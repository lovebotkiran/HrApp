import bcrypt
import psycopg2

def fix_admin_password():
    password = b"Admin@123"
    salt = bcrypt.gensalt(12)
    hashed = bcrypt.hashpw(password, salt).decode('utf-8')
    
    print(f"Generated Hash: {hashed}")
    print(f"Hash Length: {len(hashed)}")
    
    try:
        conn = psycopg2.connect("postgresql://postgres:postgres@localhost:5435/agentichr")
        cur = conn.cursor()
        cur.execute("UPDATE users SET password_hash = %s WHERE email = %s", (hashed, "admin@agentichr.com"))
        conn.commit()
        print("Update successful.")
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error updating DB: {e}")

if __name__ == "__main__":
    fix_admin_password()
