import logging
import httpx
import os
import mimetypes
from typing import Dict, Any, Optional
from PIL import Image, ImageDraw, ImageFont
from core.config import settings

logger = logging.getLogger(__name__)

class LinkedInService:
    def __init__(self):
        self.access_token = settings.LINKEDIN_ACCESS_TOKEN.strip() if hasattr(settings, 'LINKEDIN_ACCESS_TOKEN') else ""
        self.api_url = "https://api.linkedin.com/v2"
        self._bold_map = {
            'A': '𝗔', 'B': '𝗕', 'C': '𝗖', 'D': '𝗗', 'E': '𝗘', 'F': '𝗙', 'G': '𝗚', 'H': '𝗛', 'I': '𝗜', 'J': '𝗝', 'K': '𝗞', 'L': '𝗟', 'M': '𝗠', 'N': '𝗡', 'O': '𝗢', 'P': '𝗣', 'Q': '𝗤', 'R': '𝗥', 'S': '𝗦', 'T': '𝗧', 'U': '𝗨', 'V': '𝗩', 'W': '𝗪', 'X': '𝗫', 'Y': '𝗬', 'Z': '𝗭',
            'a': '𝗮', 'b': '𝗯', 'c': '𝗰', 'd': '𝗱', 'e': '𝗲', 'f': '𝗳', 'g': '𝗴', 'h': '𝗵', 'i': '𝗶', 'j': '𝗷', 'k': '𝗸', 'l': '𝗹', 'm': '𝗺', 'n': '𝗻', 'o': '𝗼', 'p': '𝗽', 'q': '𝗾', 'r': '𝗿', 's': '𝘀', 't': '𝘁', 'u': '𝘂', 'v': '𝘃', 'w': '𝘄', 'x': '𝘅', 'y': '𝘆', 'z': '𝘇',
            '0': '𝟬', '1': '𝟭', '2': '𝟮', '3': '𝟯', '4': '𝟰', '5': '𝟱', '6': '𝟲', '7': '𝟳', '8': '𝟴', '9': '𝟵'
        }
        self.template_path = os.path.join(os.getcwd(), "assets", "templates", "hiring_template.png")
        self.output_dir = os.path.join(os.getcwd(), "uploads", "generated_posts")
        os.makedirs(self.output_dir, exist_ok=True)
        
        self.org_urn = settings.LINKEDIN_ORGANIZATION_URN.strip() if hasattr(settings, 'LINKEDIN_ORGANIZATION_URN') else ""
        if "YOUR_ORG_ID_HERE" in self.org_urn:
            self.org_urn = ""
        
        # Auto-prefix if only the numerical ID was provided
        if self.org_urn and self.org_urn.isdigit():
            self.org_urn = f"urn:li:organization:{self.org_urn}"
            logger.info(f"Auto-prefixed LinkedIn Organization URN: {self.org_urn}")
        
        
    async def share_job(self, title: str, description: str, apply_url: str = "", image_path: str = None, generate_image: bool = True, logo_path: str = None, highlights: list = None) -> Dict[str, Any]:
        """
        Share a job posting to LinkedIn using the modern Posts API.
        """
        try:
            if generate_image and not image_path:
                image_path = await self.generate_hiring_image(title, logo_path, highlights)
            
            if not self.access_token:
                logger.warning("LinkedIn access token not found.")
                return {"success": False, "message": "LinkedIn access token not configured", "status_code": 401}

            formatted_title = self._to_bold(f"We are hiring a {title}!")
            formatted_description = self._format_commentary(description)
            apply_text = self._to_bold("Apply here:")
            
            # LinkedIn Posts API character limit (requested to be 10000)
            header = f"{formatted_title}\n\n"
            footer = f"\n\n{apply_text} {apply_url}"
            
            max_desc_len = 10000 - len(header) - len(footer) - 5 # extra safety
            
            if len(formatted_description) > max_desc_len:
                logger.warning(f"Commentary too long ({len(formatted_description) + len(header) + len(footer)} chars). Truncating.")
                formatted_description = formatted_description[:max_desc_len - 3] + "..."
            
            commentary = f"{header}{formatted_description}{footer}"

            # Always get the person URN first as a reliable fallback
            person_urn = await self._get_author_urn()
            
            # Use Organization URN if configured, otherwise fallback to Person URN
            author_urn = self.org_urn if self.org_urn else person_urn
            
            if not author_urn:
                return {
                    "success": False, 
                    "message": "Could not determine LinkedIn author URN. Ensure your access token is valid and has sufficient permissions (openid, profile, w_member_social).",
                    "status_code": 401
                }

            # Modern Posts API Payload
            payload = {
                "author": author_urn,
                "commentary": commentary,
                "visibility": "PUBLIC",
                "distribution": {
                    "feedDistribution": "MAIN_FEED",
                    "targetEntities": [],
                    "thirdPartyDistributionChannels": []
                },
                "lifecycleState": "PUBLISHED",
                "isReshareDisabledByAuthor": False
            }
            
            # Add media if available (registered with author_urn as owner)
            if image_path:
                asset_urn = await self._upload_image(author_urn, image_path)
                if asset_urn:
                    payload["content"] = {
                        "media": {
                            "title": title,
                            "id": asset_urn
                        }
                    }

            async with httpx.AsyncClient() as client:
                headers = {
                    "Authorization": f"Bearer {self.access_token}",
                    "X-Restli-Protocol-Version": "2.0.0",
                    "LinkedIn-Version": "202410" 
                }
                
                logger.info(f"Sharing to LinkedIn as {author_urn}. Commentary length: {len(payload['commentary'])}")
                logger.debug(f"Payload: {payload}")
                response = await client.post(
                    "https://api.linkedin.com/v2/posts",
                    headers=headers,
                    json=payload
                )
                
                if response.status_code in [201, 200]:
                    logger.info("Successfully posted to LinkedIn Organization Page.")
                    return {"success": True, "data": response.json() if response.text else {}, "message": "Successfully shared to LinkedIn Company Page"}
                
                # Fallback: If we tried to post as an organization and got 403, try as the person
                if response.status_code == 403 and author_urn.startswith("urn:li:organization:") and person_urn:
                    logger.warning(f"Failed to post as organization {author_urn} (403). Falling back to personal post as {person_urn}")
                    payload["author"] = person_urn
                    
                    # Try to re-upload image for person owner if organization owner failed
                    if image_path:
                        logger.info("Attempting to re-upload image for personal profile owner fallback...")
                        asset_urn = await self._upload_image(person_urn, image_path)
                        if asset_urn:
                            payload["content"] = {
                                "media": {
                                    "title": title,
                                    "id": asset_urn
                                }
                            }
                    else:
                        if "content" in payload:
                            del payload["content"]
                    
                    response = await client.post(
                        "https://api.linkedin.com/v2/posts",
                        headers=headers,
                        json=payload
                    )
                    if response.status_code in [201, 200]:
                        return {"success": True, "data": response.json() if response.text else {}, "message": "Posted to personal feed (organization access denied)"}

                # Try to parse error body for more detail
                error_body = None
                try:
                    error_body = response.json()
                except Exception:
                    error_body = response.text

                logger.error(f"LinkedIn API error {response.status_code} for author {author_urn}: {error_body}")
                
                # Provide a more diagnostic message to the user
                msg = f"LinkedIn Error {response.status_code} for author {author_urn}"
                if isinstance(error_body, dict) and "message" in error_body:
                    msg += f": {error_body['message']}"
                elif isinstance(error_body, str):
                    msg += f": {error_body}"

                return {
                    "success": False,
                    "message": msg,
                    "status_code": response.status_code,
                    "detail": error_body,
                    "author_used": author_urn
                }
                    
        except Exception as e:
            logger.error(f"Error sharing to LinkedIn: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return {"success": False, "message": str(e), "status_code": 500}

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
                headers = {
                    "Authorization": f"Bearer {self.access_token}",
                    "X-Restli-Protocol-Version": "2.0.0",
                    "LinkedIn-Version": "202410" 
                }
                
                reg_response = await client.post(
                    register_url,
                    headers=headers,
                    json=register_payload
                )
                
                if reg_response.status_code != 200:
                    logger.error(f"Failed to register upload: {reg_response.text}")
                    return None
                    
                reg_data = reg_response.json()
                upload_url = reg_data['value']['uploadMechanism']['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']['uploadUrl']
                asset_urn = reg_data['value']['asset']
                
                # 2. Upload Binary
                try:
                    with open(image_path, "rb") as img_file:
                        image_data = img_file.read()
                        
                    # Set appropriate content-type for upload
                    content_type, _ = mimetypes.guess_type(image_path)
                    upload_headers = {"Content-Type": content_type or "application/octet-stream"}

                    upload_response = await client.put(
                        upload_url,
                        content=image_data,
                        headers=upload_headers
                    )

                    if upload_response.status_code not in [200, 201]:
                         logger.error(f"Failed to upload image binary: {upload_response.text}")
                         return None
                    
                    # For the Posts API, we should use urn:li:image: rather than digitalmediaAsset
                    if asset_urn.startswith("urn:li:digitalmediaAsset:"):
                        return asset_urn.replace("urn:li:digitalmediaAsset:", "urn:li:image:")
                         
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
        Tries /userinfo (OIDC) first as it is preferred for new tokens,
        then falls back to legacy /me endpoint.
        """
        try:
            async with httpx.AsyncClient() as client:
                # 1. Try OIDC UserInfo first (Required for new granular scopes)
                try:
                    response = await client.get(
                        "https://api.linkedin.com/v2/userinfo",
                        headers={"Authorization": f"Bearer {self.access_token}"}
                    )
                    if response.status_code == 200:
                        data = response.json()
                        person_id = data.get("sub")
                        if person_id:
                            logger.info(f"Fetched member ID from /userinfo: {person_id}")
                            return f"urn:li:person:{person_id}"
                except Exception as e:
                    logger.debug(f"OIDC UserInfo failed: {e}")

                # 2. Fallback to legacy /me endpoint
                headers = {
                    "Authorization": f"Bearer {self.access_token}",
                    "X-Restli-Protocol-Version": "2.0.0",
                    "LinkedIn-Version": "202410"
                }
                
                response = await client.get(
                    f"{self.api_url}/me",
                    headers=headers
                )
                if response.status_code == 200:
                    data = response.json()
                    person_id = data.get('id')
                    if person_id:
                        logger.info(f"Fetched member ID from /me: {person_id}")
                        return f"urn:li:person:{person_id}"
                
                logger.error(f"Could not find person ID in LinkedIn profile. /me status: {response.status_code}")
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
        - Handles Windows line endings and cleans up whitespace.
        """
        if not text:
            return ""
            
        # Standardize line endings
        text = text.replace('\r\n', '\n').replace('\r', '\n')
        lines = text.split('\n')
        formatted_lines = []
        
        for line in lines:
            stripped = line.strip()
            
            if not stripped:
                formatted_lines.append("")
                continue

            # 1. Handle Headings starting with '#' (but not '##')
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
            elif stripped.endswith(':') and len(stripped) < 40:
                formatted_lines.append(self._to_bold(stripped))
                
            # 4. Normal text - use stripped line to avoid \r issues
            else:
                formatted_lines.append(stripped)
                
        return '\n'.join(formatted_lines)

    async def generate_hiring_image(self, title: str, logo_path: str = None, highlights: list = None) -> Optional[str]:
        """
        Generates a premiumRecruit-styled image using PIL.
        Matches the user sample style: High impact orange, clean typography, multiple sections.
        """
        try:
            # High-res canvas (LinkedIn portrait 1080x1350)
            width, height = 1080, 1350
            img = Image.new('RGB', (width, height), color=(255, 255, 255))
            draw = ImageDraw.Draw(img)

            # Modern Color Palette
            ORANGE = (255, 107, 0)      # Vivid Recruiter Orange
            NAVY = (15, 23, 42)         # Slate Navy
            WHITE = (255, 255, 255)
            LIGHT_GREY = (248, 250, 252)
            DARK_GREY = (51, 65, 85)

            # Draw top grey accent
            draw.rectangle([0, 0, width, height // 4], fill=LIGHT_GREY)
            
            # Draw main orange footer/base
            draw.rectangle([0, height - 250, width, height], fill=ORANGE)

            # Load Fonts
            font_path_bold = "C:\\Windows\\Fonts\\arialbd.ttf" if os.name == 'nt' else "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
            font_path_reg = "C:\\Windows\\Fonts\\arial.ttf" if os.name == 'nt' else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
            
            def get_font(size, bold=True):
                path = font_path_bold if bold else font_path_reg
                try:
                    return ImageFont.truetype(path, size)
                except:
                    return ImageFont.load_default()

            # 1. Main Header: "WE ARE" (Paper-like background effect placeholder)
            font_we_are = get_font(85, bold=True)
            draw.text((100, 100), "WE ARE", font=font_we_are, fill=NAVY)
            
            # 2. Hero Text: "HIRING!" (Large Orange)
            font_hiring = get_font(230, bold=True)
            draw.text((90, 170), "HIRING!", font=font_hiring, fill=ORANGE)

            # 3. Position Section
            font_section = get_font(60, bold=True)
            draw.text((100, 480), "OPEN POSITION", font=font_section, fill=ORANGE)
            
            # Position Title Bar
            draw.rectangle([80, 560, width - 80, 680], fill=NAVY)
            font_title = get_font(70, bold=True)
            title_text = title.upper()
            t_bbox = draw.textbbox((0, 0), title_text, font=font_title)
            t_w = t_bbox[2] - t_bbox[0]
            draw.text(((width - t_w) // 2, 582), title_text, font=font_title, fill=WHITE)

            # 4. Job Requirements Section
            if highlights:
                draw.text((100, 750), "JOB REQUIREMENTS", font=font_section, fill=ORANGE)
                
                y_offset = 840
                font_item = get_font(45, bold=False)
                for item in highlights[:5]:
                    # Arrowhead bullet
                    draw.polygon([(80, y_offset+10), (105, y_offset+25), (80, y_offset+40)], fill=ORANGE)
                    # Wrap/truncate text
                    txt = item if len(item) < 50 else item[:47] + "..."
                    draw.text((130, y_offset), txt, font=font_item, fill=DARK_GREY)
                    y_offset += 80

            # 5. Bottom Info (on Orange)
            font_footer_label = get_font(45, bold=True)
            font_footer_val = get_font(40, bold=False)
            
            draw.text((100, height - 190), "SUBMIT YOUR CV AT:", font=font_footer_label, fill=WHITE)
            draw.text((100, height - 135), "hr@agentichr.com", font=font_footer_val, fill=WHITE)
            
            draw.text((width - 450, height - 190), "MORE INFORMATION:", font=font_footer_label, fill=WHITE)
            draw.text((width - 450, height - 135), "www.agentichr.com", font=font_footer_val, fill=WHITE)

            # 6. Logo (Top Right)
            if logo_path and os.path.exists(logo_path):
                logo = Image.open(logo_path).convert("RGBA")
                logo.thumbnail((300, 100), Image.Resampling.LANCZOS)
                img.paste(logo, (width - 350, 100), logo)
            else:
                font_logo = get_font(55, bold=True)
                draw.text((width - 400, 110), "AGENTIC HR", font=font_logo, fill=NAVY)

            # Save
            filename = f"hiring_{title.replace(' ', '_').lower()}.png"
            output_path = os.path.join(self.output_dir, filename)
            img.save(output_path)
            
            return output_path

        except Exception as e:
            logger.error(f"Error generating premium hiring image: {e}")
            return None
