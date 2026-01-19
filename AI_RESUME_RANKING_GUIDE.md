# AI-Powered Resume Ranking System

## Overview
This system allows you to automatically scan, parse, and rank candidate resumes using AI (Ollama with Llama 3) based on job posting requirements.

## Complete Workflow

### 1. **Upload Resumes**
When candidates apply for a job posting, their resumes (PDF/DOC/DOCX) are uploaded to the system.

**Backend Endpoint**: `POST /candidates/{candidate_id}/upload-resume`
- Saves resume file to local storage
- Creates a document record in the database
- Updates candidate's `resume_url` field

### 2. **Parse Resume with AI**
The system extracts structured data from the resume using Ollama AI.

**Backend Endpoint**: `POST /candidates/{candidate_id}/parse-resume`
- Extracts text from PDF using `pdfplumber`
- Sends text to Ollama (Llama 3 model)
- AI extracts:
  - Name, email, phone
  - Skills
  - Education history
  - Work experience
  - Total years of experience
- Stores parsed data in `candidates.resume_parsed_data` (JSONB field)

**AI Service**: `AIService.parse_resume()`
```python
# Located in: backend/application/services/ai_service.py
# Uses Ollama running at http://localhost:11434
# Model: llama3
```

### 3. **Rank Candidates Against Job Requirements**
The AI compares each candidate's profile against the job description and assigns a match score.

**Backend Endpoint**: `POST /applications/rank-by-job-posting/{job_posting_id}`
- Fetches all applications for the job posting
- For each application:
  - Parses resume if not already parsed
  - Calls `AIService.rank_candidate()` to get match score (0-100)
  - Stores score in `applications.ai_match_score`
  - Stores AI reasoning in `applications.ai_match_reasoning`

**AI Service**: `AIService.rank_candidate()`
```python
# Compares:
# - Candidate skills vs required skills
# - Experience level vs job requirements
# - Returns JSON: {"score": 85, "reasoning": "Strong match..."}
```

### 4. **View Ranked Candidates**
Frontend displays candidates sorted by AI match score with visual indicators.

**Frontend Screen**: `RankedCandidatesScreen`
- Shows all candidates for a job posting
- Sorted by match score (highest first)
- Visual indicators:
  - 🟢 Green (75%+): Excellent match
  - 🟡 Yellow (50-74%): Good match
  - 🔴 Red (<50%): Poor match
- Displays AI reasoning for each candidate
- One-click ranking of all candidates

## Database Schema

### Key Tables

**candidates**
```sql
- id (UUID)
- email, first_name, last_name
- resume_url (TEXT) -- Path to uploaded resume
- resume_parsed_data (JSONB) -- AI-extracted structured data
- skills (ARRAY[TEXT])
- total_experience_years (DECIMAL)
```

**applications**
```sql
- id (UUID)
- job_posting_id (UUID)
- candidate_id (UUID)
- ai_match_score (DECIMAL 0-100)
- ai_match_reasoning (TEXT)
- status (VARCHAR)
```

**candidate_documents**
```sql
- id (UUID)
- candidate_id (UUID)
- document_type (VARCHAR) -- 'resume'
- file_url (TEXT)
- mime_type (VARCHAR)
```

## API Endpoints

### Resume Management
- `POST /candidates/{id}/upload-resume` - Upload resume file
- `POST /candidates/{id}/parse-resume` - Parse resume with AI

### Ranking
- `POST /applications/{id}/calculate-match-score` - Rank single application
- `POST /applications/rank-by-job-posting/{job_posting_id}` - Rank all applications for a job

### Viewing
- `GET /applications?job_posting_id={id}` - Get applications with scores

## Frontend Navigation

1. **Job Postings List** → Click "View Ranked Candidates"
2. **Ranked Candidates Screen** → Shows sorted list
3. Click "Rank All Candidates" → Triggers AI ranking
4. Expand candidate card → View AI reasoning
5. Click "Shortlist" → Move to next stage

## AI Configuration

**Ollama Setup**:
```bash
# Install Ollama
# Download Llama 3 model
ollama pull llama3

# Start Ollama server (default: http://localhost:11434)
ollama serve
```

**Environment Variables** (backend/.env):
```
OLLAMA_BASE_URL=http://localhost:11434
```

## Usage Example

### Step 1: Create Job Posting
```
Title: Senior Python Developer
Skills: Python, Django, PostgreSQL, Docker
Experience: 5-8 years
```

### Step 2: Candidates Apply
- Candidate uploads resume (PDF)
- System stores file and creates application

### Step 3: Rank Candidates
Navigate to Job Postings → Click "View Ranked Candidates" → Click "Rank All Candidates"

**Behind the scenes**:
1. System parses each resume
2. AI extracts skills, experience
3. AI compares against job requirements
4. Assigns match score with reasoning

### Step 4: Review Results
```
🏆 Candidate #1 - 92% Match
   "Strong Python and Django experience. 7 years total experience matches requirements perfectly."

⭐ Candidate #2 - 78% Match
   "Good Python skills, lacks Docker experience but has PostgreSQL expertise."

📊 Candidate #3 - 45% Match
   "Junior developer with 2 years experience. Skills don't align well with senior role."
```

## Benefits

✅ **Automated Screening**: No manual resume review needed
✅ **Objective Ranking**: AI provides consistent evaluation
✅ **Time Saving**: Process 100s of resumes in minutes
✅ **Detailed Insights**: AI explains why each candidate matches
✅ **Better Hiring**: Focus on top candidates first

## Technical Stack

- **Backend**: FastAPI (Python)
- **Frontend**: Flutter (Dart)
- **AI**: Ollama + Llama 3
- **Database**: PostgreSQL
- **Resume Parsing**: pdfplumber
- **LLM Framework**: LangChain

## Future Enhancements

- [ ] Support for more file formats (DOCX, TXT)
- [ ] Batch upload multiple resumes
- [ ] Custom ranking criteria per job
- [ ] Interview question generation based on resume
- [ ] Candidate comparison view
- [ ] Export ranked list to Excel/PDF
