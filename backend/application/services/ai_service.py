import json
import logging
import os
from typing import Dict, Any, List, Optional
import pdfplumber
import httpx
from langchain_community.llms import Ollama

# Configure logging
logger = logging.getLogger(__name__)

class AIService:
    def __init__(self):
        # We assume Ollama is running locally on default port
        # Use host.docker.internal if running in Docker and Ollama is on host
        self.ollama_base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
        self.model_name = "llama3" 
        self.llm = Ollama(
            base_url=self.ollama_base_url, 
            model=self.model_name,
            num_predict=2048,
            num_ctx=4096
        )

    async def extract_text_from_file(self, file_path: str, mime_type: str = "application/pdf") -> str:
        """Extracts text from PDF or plain text files."""
        try:
            if "pdf" in mime_type or file_path.endswith(".pdf"):
                text = ""
                with pdfplumber.open(file_path) as pdf:
                    for page in pdf.pages:
                        extracted = page.extract_text()
                        if extracted:
                            text += extracted + "\n"
                return text
            else:
                # Fallback for text files
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    return f.read()
        except Exception as e:
            logger.error(f"Error extracting text from {file_path}: {e}")
            return ""

    async def parse_resume(self, file_path: str, mime_type: str = "application/pdf") -> Dict[str, Any]:
        """Parses resume text into structured JSON using LLM."""
        text = await self.extract_text_from_file(file_path, mime_type)
        if not text:
            return {"error": "Could not extract text"}

        prompt = f"""
        You are an expert technical recruiter. Analyze the following resume text and extract the key details into a structured JSON format.
        
        Return ONLY valid JSON. Do not include any explanation or markdown formatting like ```json.
        
        Required JSON Structure:
        {{
            "first_name": "string",
            "last_name": "string",
            "email": "string",
            "phone": "string",
            "skills": ["string", "string"],
            "education": [
                {{ "degree": "string", "institution": "string", "year": "string" }}
            ],
            "experience": [
                {{ "company": "string", "role": "string", "duration": "string", "description": "string" }}
            ],
            "total_experience_years": number,
            "highest_education": "string",
            "current_company": "string",
            "current_designation": "string"
        }}
        
        Resume Text:
        {text[:8000]}
        """
        
        try:
            response = self.llm.invoke(prompt)
            # Naive cleanup of response to finding JSON block
            start_idx = response.find('{')
            end_idx = response.rfind('}') + 1
            if start_idx != -1 and end_idx != -1:
                json_str = response[start_idx:end_idx]
                return json.loads(json_str)
            else:
                logger.warning(f"AI response did not contain JSON: {response}")
                return {"error": "AI failed to generate JSON", "raw_response": response}
        except Exception as e:
            logger.error(f"Error calling LLM for resume parsing: {e}")
            return {"error": str(e)}

    async def generate_jd(self, title: str, skills: List[str], experience_min: int, experience_max: int) -> str:
        """Generates a job description based on criteria."""
        prompt = f"""
        Write a compelling and professional Job Description for the following position:
        
        Role: {title}
        Required Skills: {', '.join(skills)}
        Experience Level: {experience_min} to {experience_max} years
        
        Structure the JD with exactly these headers and markers for LinkedIn formatting:
        - Use # for main section headers (e.g., # About the Role)
        - Use ## for bullet points or list items (e.g., ## Proficiency in Python)
        - Close sections with a newline.
        
        Sections to include:
        1. # About the Role
        2. # Key Responsibilities
        3. # Requirements
        4. # What We Offer
        
        Tone: Professional, engaging, and modern.
        
        IMPORTANT: Return ONLY the content of the job description. Do NOT include any introductory text (like "Here is the JD") or concluding notes. Start directly with the first section header.
        """
        response = self.llm.invoke(prompt)
        
        # Post-processing to ensure no filler remains if the LLM slips up
        # We expect the first line to start with '#'
        lines = response.strip().split('\n')
        start_index = 0
        for i, line in enumerate(lines):
            if line.strip().startswith('# '):
                start_index = i
                break
        
        # If we found a header, assume content starts there. 
        # Also strip trailing notes (often starting with "Note:" or "Hope this helps")
        cleaned_lines = lines[start_index:]
        final_content = []
        for line in reversed(cleaned_lines):
            if line.strip().lower().startswith("note:") or "let me know" in line.lower():
                continue
            final_content.append(line)
            
        return '\n'.join(reversed(final_content)).strip()

    async def rank_candidate(self, job_description: str, candidate_profile_json: Dict) -> Dict[str, Any]:
        """Compares candidate profile against JD and returns a score."""
        candidate_summary = f"""
        Skills: {', '.join(candidate_profile_json.get('skills', []))}
        Exp: {candidate_profile_json.get('total_experience_years', 0)} years
        """
        
        prompt = f"""
        Act as a Hiring Manager. Evaluate the Candidate against the Job Description.
        
        Job Description:
        {job_description[:4000]}
        
        Candidate Profile:
        {candidate_summary}
        
        Return ONLY valid JSON:
        {{
            "score": number (0-100),
            "reasoning": "string (max 100 words explaining the score)"
        }}
        """
        
        try:
            response = self.llm.invoke(prompt)
            start_idx = response.find('{')
            end_idx = response.rfind('}') + 1
            if start_idx != -1:
                return json.loads(response[start_idx:end_idx])
            else:
                return {"score": 0, "reasoning": "Parsing Error"}
        except Exception as e:
            logger.error(f"Error ranking candidate: {e}")
            return {"score": 0, "reasoning": f"AI Error: {e}"}
