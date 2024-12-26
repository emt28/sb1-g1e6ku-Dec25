/*
  # Create Assessments Table
  
  Creates the assessments table for tracking athlete performance measurements.
  
  1. Table Structure:
    - assessments: Performance test results linked to athletes and protocols
  
  2. Security:
    - RLS enabled
    - Management access for coaches and trainers
*/

-- Create assessments table
CREATE TABLE IF NOT EXISTS assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id uuid REFERENCES athletes NOT NULL,
  protocol_id uuid REFERENCES protocols NOT NULL,
  value numeric NOT NULL,
  performance_level text CHECK (performance_level IN ('needs_improvement', 'median', 'excellent')),
  notes text,
  assessed_by uuid REFERENCES auth.users NOT NULL,
  assessed_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

-- Create policy if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'assessments' 
    AND policyname = 'Coaches can manage assessments'
  ) THEN
    CREATE POLICY "Coaches can manage assessments" ON assessments
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer')
      ));
  END IF;
END $$;