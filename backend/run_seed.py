import os
import sys
import psycopg2
from core.config import settings

def run_seed():
    print("Running seed script using psycopg2...")
    sql_path = os.path.join(os.path.dirname(__file__), "..", "database", "seed_data.sql")
    
    if not os.path.exists(sql_path):
        print(f"Error: seed_data.sql not found at {sql_path}")
        return

    with open(sql_path, 'r') as f:
        sql = f.read()

    # Database connection URL
    url = settings.DATABASE_URL
    # Handle the 'postgresql+psycopg2://' format if present
    if '+' in url:
        url = url.split('+')[0] + url.split('://')[1]
        if not url.startswith('postgresql://'):
             url = 'postgresql://' + url

    try:
        conn = psycopg2.connect(url)
        conn.autocommit = True
        cur = conn.cursor()
        
        cur.execute(sql)
        
        print("✓ Database seeded successfully.")
        conn.close()
    except Exception as e:
        print(f"X Failed to seed database: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    run_seed()
