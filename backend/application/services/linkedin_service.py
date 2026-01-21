import logging
import httpx
from typing import Dict, Any, Optional
from core.config import settings

logger = logging.getLogger(__name__)

class LinkedInService:
    def __init__(self):
        self.access_token = settings.LINKEDIN_ACCESS_TOKEN if hasattr(settings, 'LINKEDIN_ACCESS_TOKEN') else ""
        self.api_url = "https://api.linkedin.com/v2"
        self._bold_map = {
            'A': '𝗔', 'B': '𝗕', 'C': '𝗖', 'D': '𝗗', 'E': '𝗘', 'F': '𝗙', 'G': '𝗚', 'H': '𝗛', 'I': '𝗜', 'J': '𝗝', 'K': '𝗞', 'L': '𝗟', 'M': '𝗠', 'N': '𝗡', 'O': '𝗢', 'P': '𝗣', 'Q': '𝗤', 'R': '𝗥', 'S': '𝗦', 'T': '𝗧', 'U': '𝗨', 'V': '𝗩', 'W': '𝗪', 'X': '𝗫', 'Y': '𝗬', 'Z': '𝗭',
            'a': '𝗮', 'b': '𝗯', 'c': '𝗰', 'd': '𝗱', 'e': '𝗲', 'f': '𝗳', 'g': '𝗴', 'h': '𝗵', 'i': '𝗶', 'j': '𝗷', 'k': '𝗸', 'l': '𝗹', 'm': '𝗺', 'n': '𝗻', 'o': '𝗼', 'p': '𝗽', 'q': '𝗾', 'r': '𝗿', 's': '𝘀', 't': '𝘁', 'u': '𝘂', 'v': '𝘃', 'w': '𝘄', 'x': '𝘅', 'y': '𝘆', 'z': '𝘇',
            '0': '𝟬', '1': '𝟭', '2': '𝟮', '3': '𝟯', '4': '𝟰', '5': '𝟱', '6': '𝟲', '7': '𝟳', '8': '𝟴', '9': '𝟵'
        }
        
        
    async def share_job(self, title: str, description: str, apply_url: str = "", image_path: str = None) -> Dict[str, Any]:
        """
        Share a job posting to LinkedIn using the modern Posts API.
        """
        if not self.access_token:
            logger.warning("LinkedIn access token not found.")
            return {"success": False, "message": "LinkedIn access token not configured"}

        formatted_title = self._to_bold(f"We are hiring a {title}!")
        formatted_description = self._format_commentary(description)
        apply_text = self._to_bold("Apply here:")
        
        share_text = f"{formatted_title}\n\n{formatted_description}\n\n{apply_text} {apply_url}"
        
        # Always get the person URN first as a reliable fallback
        person_urn = await self._get_author_urn()
        
        # Try to use Organization URN if configured, otherwise fallback to Person URN
        author_urn = settings.LINKEDIN_ORGANIZATION_URN if settings.LINKEDIN_ORGANIZATION_URN and "YOUR_ORG_ID_HERE" not in settings.LINKEDIN_ORGANIZATION_URN else None
        
        if not author_urn:
            author_urn = person_urn
            
        if not author_urn:
            return {"success": False, "message": "Could not determine LinkedIn author URN (Person or Organization). Ensure your access token is valid and has sufficient permissions."}

        # Modern Posts API Payload
        payload = {
            "author": author_urn,
            "commentary": share_text,
            "visibility": "PUBLIC",
            "distribution": {
                "feedDistribution": "MAIN_FEED",
                "targetEntities": [],
                "thirdPartyDistributionChannels": []
            },
            "lifecycleState": "PUBLISHED",
            "isReshareDisabledByAuthor": False
        }
        
        # Add media if available
        if image_path:
            asset_urn = await self._upload_image(author_urn, image_path)
            if asset_urn:
                payload["content"] = {
                    "media": {
                        "title": title,
                        "id": asset_urn
                    }
                }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://api.linkedin.com/v2/posts",
                    headers={
                        "Authorization": f"Bearer {self.access_token}",
                        "X-Restli-Protocol-Version": "2.0.0",
                        "LinkedIn-Version": "202401" # Use a recent version
                    },
                    json=payload
                )
                
                if response.status_code in [201, 200]:
                    return {"success": True, "data": response.json() if response.text else {}}
                
                # Fallback: If we tried to post as an organization and got 403, try as the person
                if response.status_code == 403 and author_urn.startswith("urn:li:organization:") and person_urn:
                    logger.warning(f"Failed to post as organization {author_urn} (403). Falling back to personal post as {person_urn}")
                    payload["author"] = person_urn
                    response = await client.post(
                        "https://api.linkedin.com/v2/posts",
                        headers={
                            "Authorization": f"Bearer {self.access_token}",
                            "X-Restli-Protocol-Version": "2.0.0",
                            "LinkedIn-Version": "202401"
                        },
                        json=payload
                    )
                    if response.status_code in [201, 200]:
                        return {"success": True, "data": response.json() if response.text else {}, "message": "Posted to personal feed (organization access denied)"}

                logger.error(f"LinkedIn API error {response.status_code}: {response.text}")
                return {
                    "success": False, 
                    "message": f"LinkedIn Error: {response.status_code}", 
                    "status_code": response.status_code,
                    "detail": response.text
                }
                    
        except Exception as e:
            logger.error(f"Error sharing to LinkedIn: {e}")
            return {"success": False, "message": str(e)}

    async def _upload_image(self, author_urn: str, image_path: str) -> Optional[str]:
        """
        Uploads an image to LinkedIn and returns the asset URN.
        1. Register upload
        2. Upload binary
        """
        try:
            # 1. Register Upload
            register_url = "https://api.linkedin.com/v2/assets?action=registerUpload"
            
            register_payload = {
                "registerUploadRequest": {
                    "recipes": [
                        "urn:li:digitalmediaRecipe:feedshare-image"
                    ],
                    "owner": author_urn,
                    "serviceRelationships": [
                        {
                            "relationshipType": "OWNER",
                            "identifier": "urn:li:userGeneratedContent"
                        }
                    ]
                }
            }
            
            async with httpx.AsyncClient() as client:
                reg_response = await client.post(
                    register_url,
                    headers={
                        "Authorization": f"Bearer {self.access_token}",
                        "X-Restli-Protocol-Version": "2.0.0"
                    },
                    json=register_payload
                )
                
                if reg_response.status_code != 200:
                    logger.error(f"Failed to register upload: {reg_response.text}")
                    return None
                    
                reg_data = reg_response.json()
                upload_url = reg_data['value']['uploadMechanism']['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']['uploadUrl']
                asset_urn = reg_data['value']['asset']
                
                # 2. Upload Binary
                # Just reading the file as binary
                try:
                    with open(image_path, "rb") as img_file:
                        image_data = img_file.read()
                        
                    upload_response = await client.put(
                        upload_url,
                        headers={
                            "Authorization": f"Bearer {self.access_token}"
                        },
                        content=image_data
                    )
                    
                    if upload_response.status_code not in [200, 201]:
                         logger.error(f"Failed to upload image binary: {upload_response.text}")
                         return None
                         
                    return asset_urn
                    
                except Exception as e:
                    logger.error(f"Error reading/uploading image file: {e}")
                    return None
                    
        except Exception as e:
            logger.error(f"Error in image upload flow: {e}")
            return None

    async def _get_author_urn(self) -> Optional[str]:
        """
        Fetch the current user's URN (ID or Sub) to use as author.
        Tries /me endpoint first, then /userinfo for OIDC tokens.
        """
        try:
            async with httpx.AsyncClient() as client:
                # Try OIDC UserInfo first as it's more reliable for new tokens
                response = await client.get(
                    "https://api.linkedin.com/v2/userinfo",
                    headers={"Authorization": f"Bearer {self.access_token}"}
                )
                
                if response.status_code == 200:
                    data = response.json()
                    # OIDC uses 'sub' as the person identifier
                    person_id = data.get("sub")
                    if person_id:
                        return f"urn:li:person:{person_id}"

                # Fallback to legacy /me endpoint
                response = await client.get(
                    f"{self.api_url}/me",
                    headers={
                        "Authorization": f"Bearer {self.access_token}",
                        "X-Restli-Protocol-Version": "2.0.0",
                        "LinkedIn-Version": "202401"
                    }
                )
                if response.status_code == 200:
                    data = response.json()
                    person_id = data.get('id')
                    if person_id:
                        return f"urn:li:person:{person_id}"
                
                logger.error(f"Could not find person ID in LinkedIn profile. Status: {response.status_code}")
                return None
        except Exception as e:
            logger.error(f"Error fetching LinkedIn profile: {e}")
            return None

    def get_authorization_url(self, redirect_uri: str, state: str) -> str:
        """
        Generate the LinkedIn OAuth2 authorization URL.
        """
        params = {
            "response_type": "code",
            "client_id": settings.LINKEDIN_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "state": state,
            "scope": "openid profile email w_member_social w_organization_social",
        }
        url = "https://www.linkedin.com/oauth/v2/authorization?" + "&".join(f"{k}={v}" for k, v in params.items())
        return url

    async def get_access_token(self, code: str, redirect_uri: str) -> Optional[str]:
        """
        Exchange authorization code for an access token.
        """
        url = "https://www.linkedin.com/oauth/v2/accessToken"
        data = {
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
            "client_id": settings.LINKEDIN_CLIENT_ID,
            "client_secret": settings.LINKEDIN_CLIENT_SECRET,
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(url, data=data)
                if response.status_code == 200:
                    return response.json().get("access_token")
                else:
                    logger.error(f"Failed to get LinkedIn access token: {response.text}")
                    return None
        except Exception as e:
            logger.error(f"Error exchanging LinkedIn code: {e}")
            return None

    async def get_user_info(self, access_token: str) -> Optional[Dict[str, Any]]:
        """
        Get user info using OpenID Connect userinfo endpoint.
        """
        url = "https://api.linkedin.com/v2/userinfo"
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    url,
                    headers={"Authorization": f"Bearer {access_token}"}
                )
                if response.status_code == 200:
                    return response.json()
                else:
                    logger.error(f"Failed to get LinkedIn user info: {response.text}")
                    return None
        except Exception as e:
            logger.error(f"Error fetching LinkedIn user info: {e}")
            return None

    def _to_bold(self, text: str) -> str:
        """Converts text to Unicode bold characters."""
        return "".join(self._bold_map.get(c, c) for c in text)

    def _format_commentary(self, text: str) -> str:
        """
        Formats the description for a professional LinkedIn look:
        - # MAIN HEADER -> **BOLD UPPERCASE**
        - # Sub-heading: -> **Bold Title Case**
        - ## List Item -> • List Item
        - Paragraphs -> Standard text
        """
        lines = text.split('\n')
        formatted_lines = []
        
        for line in lines:
            stripped = line.strip()
            
            # 1. Handle Headings starting with '#'
            if stripped.startswith('#') and not stripped.startswith('##'):
                content = stripped.lstrip('#').strip()
                if content.endswith(':'):
                    # Sub-heading/Label with colon (e.g. # Skills:)
                    formatted_lines.append(self._to_bold(content))
                else:
                    # Main Section Header (# About the Role)
                    formatted_lines.append(f"\n{self._to_bold(content.upper())}")
            
            # 2. Handle Bullet Points (## Item) -> Become "• Item"
            elif stripped.startswith('##'):
                content = stripped.lstrip('##').strip()
                formatted_lines.append(f"• {content}")
                
            # 3. Handle sub-labels that might not have # but end in : (e.g. Compensation:)
            elif stripped.endswith(':') and len(stripped) < 40 and not stripped.startswith('#'):
                formatted_lines.append(self._to_bold(stripped))
                
            # 4. Normal text
            else:
                formatted_lines.append(line)
                
        return '\n'.join(formatted_lines)
