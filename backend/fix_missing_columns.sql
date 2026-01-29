
-- Fix missing columns in interviews table
ALTER TABLE interviews ADD COLUMN IF NOT EXISTS feedback_submitted BOOLEAN DEFAULT FALSE;
ALTER TABLE interviews ADD COLUMN IF NOT EXISTS overall_rating DECIMAL(3, 1);

-- Fix missing columns in job_postings table
ALTER TABLE job_postings ADD COLUMN IF NOT EXISTS status_state VARCHAR(50) DEFAULT 'Draft';

-- Add index for status_state if it doesn't exist (names might vary, safe to skip or try)
CREATE INDEX IF NOT EXISTS idx_job_postings_status_state ON job_postings(status_state);
