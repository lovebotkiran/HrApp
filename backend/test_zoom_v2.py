import asyncio
import httpx
import base64
import logging
import sys

# Configure logging
logging.basicConfig(level=logging.ERROR)
logger = logging.getLogger(__name__)

# Credentials from .env
ACCOUNT_ID = "eApapCraT066pxBTAKf1qA"
CLIENT_ID = "jAibQccwTpms9hDzAZt67Q"
CLIENT_SECRET = "kkKsOR5xant1SduhQwfipkW9DEKxM81A"

async def test_zoom_connection():
    print("Testing Zoom Connection (Server-to-Server OAuth)...")
    
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
    
    print("\n1. Requesting Access Token...")
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(auth_url, params=params, headers=headers)
            
            if response.status_code != 200:
                print(f"FAILED to get token: {response.text}")
                return
                
            data = response.json()
            access_token = data.get("access_token")
            print(f"✓ Access Token received. Scope: {data.get('scope')}")
            
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            # 2. List Users to find a host
            print("\n2. Listing Users to find a host...")
            users_url = "https://api.zoom.us/v2/users"
            response = await client.get(users_url, headers=headers)
            
            host_id = None
            if response.status_code == 200:
                users_data = response.json()
                users_list = users_data.get('users', [])
                print(f"✓ Found {len(users_list)} users")
                if users_list:
                    host_id = users_list[0]['id']
                    host_email = users_list[0]['email']
                    print(f"  Using Host: {host_email} (ID: {host_id})")
            else:
                print(f"FAILED to list users: {response.text}")
                # Fallback to 'me' if listing fails, though 'me' might be the issue
                host_id = 'me' 
            
            if not host_id:
                print("No users found to host the meeting.")
                return

            # 3. Create Meeting for specific host
            print(f"\n3. Creating Meeting for host {host_id}...")
            meeting_url = f"https://api.zoom.us/v2/users/{host_id}/meetings"
            payload = {
                "topic": "Test Meeting (AgenticHR)",
                "type": 2,
                "start_time": "2026-02-01T10:00:00Z",
                "duration": 30,
                "timezone": "UTC"
            }
            
            response = await client.post(meeting_url, json=payload, headers=headers)
            
            if response.status_code == 201:
                meeting_data = response.json()
                print(f"✓ Meeting Created Successfully!")
                print(f"  Join URL: {meeting_data.get('join_url')}")
            else:
                print(f"FAILED to create meeting: {response.status_code}")
                print(f"Error Response: {response.text}")
                
        except Exception as e:
            print(f"Exception: {e}")

if __name__ == "__main__":
    asyncio.run(test_zoom_connection())
