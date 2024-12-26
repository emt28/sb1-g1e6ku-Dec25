/*
  # Coach Notes Table
  
  Creates a table for storing coach notes and feedback about athletes.
  
  1. Table Structure:
    - id: UUID primary key
    - athlete_id: Reference to athlete
    - content: Note content
    - type: Note category (general, technical, tactical, physical, mental)
    - visibility: Who can see the note (coaches or all)
    - created_by: Reference to user who created note
    - created_at: Creation timestamp
  
  2. Security:
    - RLS enabled
    - Only coaches can manage notes
*/

-- Create coach notes table
CREATE TABLE IF NOT EXISTS coach_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id uuid REFERENCES athletes NOT NULL,
  content text NOT NULL,
  type text CHECK (type IN ('general', 'technical', 'tactical', 'physical', 'mental')),
  visibility text CHECK (visibility IN ('coaches', 'all')),
  created_by uuid REFERENCES auth.users NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE coach_notes ENABLE ROW LEVEL SECURITY;

-- Create policy if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'coach_notes' 
    AND policyname = 'Coaches can manage notes'
  ) THEN
    CREATE POLICY "Coaches can manage notes" ON coach_notes
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer')
      ));
  END IF;
END $$;