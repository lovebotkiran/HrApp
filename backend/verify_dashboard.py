
import sys
import os
import asyncio
from fastapi.testclient import TestClient
from main import app
from infrastructure.security.auth import get_current_user
from infrastructure.database.models import User

# Mock user
def mock_get_current_user():
    return User(id="99999999-9999-9999-9999-999999999999", email="admin@test.com", first_name="Admin", last_name="User")

app.dependency_overrides[get_current_user] = mock_get_current_user

client = TestClient(app)

def test_dashboard():
    print("Testing /dashboard/pipeline...")
    try:
        response = client.get("/api/v1/dashboard/pipeline")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        if response.status_code != 200:
            print("ERROR IN PIPELINE")
            sys.exit(1)
    except Exception as e:
        print(f"EXCEPTION: {e}")
        sys.exit(1)

    print("\nTesting /dashboard/metrics...")
    try:
        response = client.get("/api/v1/dashboard/metrics")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        if response.status_code != 200:
            print("ERROR IN METRICS")
            sys.exit(1)
    except Exception as e:
        print(f"EXCEPTION: {e}")
        sys.exit(1)

    print("\nSUCCESS: All dashboard endpoints working.")

if __name__ == "__main__":
    # Ensure env vars are set if needed (DATABASE_URL etc should be in .env or defaults)
    test_dashboard()
