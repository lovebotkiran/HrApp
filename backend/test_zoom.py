import asyncio
import httpx
import base64
import logging
import sys

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Credentials from .env
ACCOUNT_ID = "eApapCraT066pxBTAKf1qA"
CLIENT_ID = "jAibQccwTpms9hDzAZt67Q"
CLIENT_SECRET = "kkKsOR5xant1SduhQwfipkW9DEKxM81A"

async def test_zoom_connection():
    print("Testing Zoom Connection...")
    print(f"Account ID: {ACCOUNT_ID}")
    print(f"Client ID: {CLIENT_ID}")
    
    # 1. Get Access Token
    auth_url = "https://zoom.us/oauth/token"
    auth_header = base64.b64encode(f"{CLIENT_ID}:{CLIENT_SECRET}".encode()).decode()
    
    headers = {
        "Authorization": f"Basic {auth_header}"
    }
    
    params = {
        "grant_type": "account_credentials",
        "account_id": ACCOUNT_ID
    }
    
    print("\nRequesting Access Token...")
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(auth_url, params=params, headers=headers)
            print(f"Status Code: {response.status_code}")
            
            if response.status_code != 200:
                print(f"Error Response: {response.text}")
                return
                
            data = response.json()
            access_token = data.get("access_token")
            print("✓ Access Token received successfully")
            
            # 2. Extract User Info / Verify Token
            print("\nVerifying Token / Getting User Info...")
            user_url = "https://api.zoom.us/v2/users/me"
            headers = {
                "Authorization": f"Bearer {access_token}"
            }
            
            response = await client.get(user_url, headers=headers)
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                user_data = response.json()
                print(f"✓ Connected as: {user_data.get('email', 'Unknown')}")
            else:
                print(f"Error getting user info: {response.text}")
                
            # 3. Try to Create a Meeting
            print("\nTrying to Create a Test Meeting...")
            meeting_url = "https://api.zoom.us/v2/users/me/meetings"
            payload = {
                "topic": "Test Meeting from AgenticHR",
                "type": 2,
                "start_time": "2026-01-28T10:00:00Z",
                "duration": 30
            }
            
            response = await client.post(meeting_url, json=payload, headers=headers)
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 201:
                meeting_data = response.json()
                print(f"✓ Meeting Created Successfully")
                print(f"Join URL: {meeting_data.get('join_url')}")
            else:
                print(f"Error creating meeting: {response.text}")
                
        except Exception as e:
            print(f"Exception: {e}")

if __name__ == "__main__":
    asyncio.run(test_zoom_connection())
