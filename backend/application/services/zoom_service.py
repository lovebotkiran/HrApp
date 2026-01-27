import httpx
import logging
import base64
from datetime import datetime
from sqlalchemy.orm import Session
from core.config import settings
from infrastructure.database.models import Configuration

logger = logging.getLogger(__name__)

class ZoomService:
    def __init__(self):
        # Defaults from settings
        self.account_id = settings.ZOOM_ACCOUNT_ID
        self.client_id = settings.ZOOM_CLIENT_ID
        self.client_secret = settings.ZOOM_CLIENT_SECRET
        self.enabled = settings.ZOOM_ENABLED
        self.base_url = "https://api.zoom.us/v2"
        self.auth_url = "https://zoom.us/oauth/token"

    def _get_config(self, db: Session, key: str, default: str = None):
        """Fetch configuration from DB if available."""
        if not db:
            return default
        try:
            config = db.query(Configuration).filter(Configuration.key == key).first()
            return config.value if config else default
        except Exception:
            return default

    async def get_access_token(self, db: Session = None):
        """
        Get Zoom Access Token using Server-to-Server OAuth.
        """
        account_id = self._get_config(db, "zoom_account_id", self.account_id)
        client_id = self._get_config(db, "zoom_client_id", self.client_id)
        client_secret = self._get_config(db, "zoom_client_secret", self.client_secret)

        if not all([account_id, client_id, client_secret]):
            logger.error("Zoom credentials missing")
            return None

        auth_header = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()
        
        headers = {
            "Authorization": f"Basic {auth_header}"
        }
        
        params = {
            "grant_type": "account_credentials",
            "account_id": account_id
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(self.auth_url, params=params, headers=headers)
                response.raise_for_status()
                data = response.json()
                return data.get("access_token")
            except Exception as e:
                logger.error(f"Error getting Zoom access token: {e}")
                if hasattr(e, 'response') and e.response:
                    try:
                        logger.error(f"Zoom API Error Detail: {e.response.text}")
                    except Exception:
                        pass
                return None

    async def create_meeting(self, topic: str, start_time: datetime, duration: int = 60, db: Session = None):
        """
        Create a Zoom meeting.
        """
        if not self.enabled:
            logger.info(f"ZOOM DISABLED: Would have created meeting for '{topic}'")
            return "https://zoom.us/j/mock-meeting-link"

        token = await self.get_access_token(db=db)
        if not token:
            raise Exception("Failed to authenticate with Zoom. Check credentials.")

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

        # Format start_time as ISO 8601
        start_time_str = start_time.strftime("%Y-%m-%dT%H:%M:%S")

        payload = {
            "topic": topic,
            "type": 2,  # Scheduled meeting
            "start_time": start_time_str,
            "duration": duration,
            "timezone": "UTC",
            "settings": {
                "host_video": True,
                "participant_video": True,
                "join_before_host": False,
                "mute_upon_entry": True,
                "watermark": False,
                "use_pmi": False,
                "approval_type": 0,
                "audio": "both",
                "auto_recording": "none"
            }
        }

        async with httpx.AsyncClient() as client:
            try:
                url = f"{self.base_url}/users/me/meetings"
                response = await client.post(url, json=payload, headers=headers)
                
                if response.status_code != 201:
                    logger.error(f"Zoom API Error: {response.status_code} - {response.text}")
                    try:
                        message = response.json().get('message', response.text)
                    except Exception:
                        message = response.text
                    raise Exception(f"Zoom API Error: {message}")
                    
                data = response.json()
                return data.get("join_url")
            except Exception as e:
                logger.error(f"Error creating Zoom meeting: {e}")
                raise e
