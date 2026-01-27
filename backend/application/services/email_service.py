import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
from core.config import settings
from sqlalchemy.orm import Session
from infrastructure.database.models import Configuration

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        # Default config from env
        self.enabled = settings.EMAIL_ENABLED
        self.host = settings.SMTP_HOST
        self.port = settings.SMTP_PORT
        self.user = settings.SMTP_USER
        self.password = settings.SMTP_PASSWORD
        self.from_email = settings.SMTP_FROM_EMAIL
        self.from_name = settings.SMTP_FROM_NAME

    def _get_config(self, db: Session, key: str, default: str = None):
        """Fetch configuration from DB if available."""
        if not db:
            return default
        try:
            config = db.query(Configuration).filter(Configuration.key == key).first()
            return config.value if config else default
        except Exception:
            return default

    async def send_email(self, recipient_email: str, subject: str, body: str, html_body: str = None, db: Session = None):
        """
        Send an email to a recipient.
        Checks DB for config first if db session is provided.
        """
        # Resolve configuration (DB > Env)
        # Note: Map DB keys to env var concepts
        host = self._get_config(db, "smtp_host", self.host)
        port = int(self._get_config(db, "smtp_port", str(self.port)))
        user = self._get_config(db, "smtp_user", self.user)
        password = self._get_config(db, "smtp_password", self.password)
        from_email = self._get_config(db, "smtp_from_email", self.from_email)
        from_name = self._get_config(db, "smtp_from_name", self.from_name)
        
        # Check enabled status (env only for now as global switch)
        if not self.enabled:
            logger.info(f"EMAIL DISABLED: Would have sent email to {recipient_email} with subject '{subject}'")
            logger.info(f"Body: {body[:100]}...")
            return True

        if not all([host, port, user, password]):
            logger.error("SMTP credentials missing")
            return False

        try:
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = f"{from_name} <{from_email}>"
            message["To"] = recipient_email

            part1 = MIMEText(body, "plain")
            message.attach(part1)

            if html_body:
                part2 = MIMEText(html_body, "html")
                message.attach(part2)

            with smtplib.SMTP(host, port) as server:
                server.starttls()
                server.login(user, password)
                server.sendmail(from_email, recipient_email, message.as_string())
            
            logger.info(f"Email sent successfully to {recipient_email}")
            return True
        except Exception as e:
            logger.error(f"Error sending email to {recipient_email}: {e}")
            return False

    async def send_interview_invitation(self, candidate_email: str, candidate_name: str, job_title: str, meeting_link: str, scheduled_at: str, db: Session = None):
        """
        Send interview invitation with meeting link.
        """
        subject = f"Interview Invitation: {job_title}"
        body = f"""
Dear {candidate_name},

We are pleased to invite you for an interview for the {job_title} position.

Interview Details:
Date & Time: {scheduled_at}
Meeting Link: {meeting_link}

Please join the meeting using the link provided above at the scheduled time.

Best regards,
The Recruitment Team
{self.from_name}
        """
        
        html_body = f"""
        <html>
        <body>
            <h2>Interview Invitation</h2>
            <p>Dear {candidate_name},</p>
            <p>We are pleased to invite you for an interview for the <strong>{job_title}</strong> position.</p>
            <p><strong>Interview Details:</strong></p>
            <ul>
                <li><strong>Date & Time:</strong> {scheduled_at}</li>
                <li><strong>Meeting Link:</strong> <a href="{meeting_link}">{meeting_link}</a></li>
            </ul>
            <p>Please join the meeting using the link provided above at the scheduled time.</p>
            <p>Best regards,<br>
            The Recruitment Team<br>
            {self.from_name}</p>
        </body>
        </html>
        """
        
        return await self.send_email(candidate_email, subject, body, html_body, db=db)

    async def send_interviewer_assignment(self, interviewer_email: str, interviewer_name: str, candidate_name: str, job_title: str, meeting_link: str, scheduled_at: str, db: Session = None):
        """
        Send interview assignment email to interviewer.
        """
        subject = f"Interview Assigned: {candidate_name} - {job_title}"
        body = f"""
Dear {interviewer_name},

You have been assigned to conduct an interview with {candidate_name} for the {job_title} position.

Interview Details:
Date & Time: {scheduled_at}
Meeting Link: {meeting_link}

Please join using the link provided above at the scheduled time.

Best regards,
AgenticHR Notification
        """
        
        html_body = f"""
        <html>
        <body>
            <h2>Interview Assignment</h2>
            <p>Dear {interviewer_name},</p>
            <p>You have been assigned to conduct an interview with <strong>{candidate_name}</strong> for the <strong>{job_title}</strong> position.</p>
            <p><strong>Interview Details:</strong></p>
            <ul>
                <li><strong>Date & Time:</strong> {scheduled_at}</li>
                <li><strong>Meeting Link:</strong> <a href="{meeting_link}">{meeting_link}</a></li>
            </ul>
            <p>Please join using the link provided above at the scheduled time.</p>
            <p>Best regards,<br>
            AgenticHR Notification</p>
        </body>
        </html>
        """
        
        return await self.send_email(interviewer_email, subject, body, html_body, db=db)
