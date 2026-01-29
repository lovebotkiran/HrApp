
-- Fix missing created_by columns
ALTER TABLE interviews ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
ALTER TABLE offers ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
