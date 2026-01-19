import psycopg2
try:
    conn = psycopg2.connect("postgresql://postgres:postgres@localhost:5432/agentichr")
    cur = conn.cursor()
    new_hash = "$2b$12$zCDUhXOZP7N76ewrYfLXq.99rv38MSlY/Dt535TSoT8AVKj/lvVxFW"
    cur.execute("UPDATE users SET password_hash = %s WHERE email = %s", (new_hash, "admin@agentichr.com"))
    conn.commit()
    print("Successfully updated password hash.")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
