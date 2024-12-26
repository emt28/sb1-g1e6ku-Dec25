/*
  # Create Athletes Table
  
  Creates the athletes table for managing athlete profiles.
  
  1. Table Structure:
    - athletes: Basic athlete information including name, DOB, and WTN
  
  2. Security:
    - RLS enabled
    - Coach management policy
*/

-- Create athletes table
CREATE TABLE IF NOT EXISTS athletes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  date_of_birth date NOT NULL,
  dominant_hand text CHECK (dominant_hand IN ('left', 'right', 'ambidextrous')),
  wtn numeric NOT NULL,
  is_active boolean DEFAULT true,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE athletes ENABLE ROW LEVEL SECURITY;

-- Create policy if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'athletes' 
    AND policyname = 'Coaches can manage athletes'
  ) THEN
    CREATE POLICY "Coaches can manage athletes" ON athletes
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'lead_coach', 'academy_coach')
      ));
  END IF;
END $$;