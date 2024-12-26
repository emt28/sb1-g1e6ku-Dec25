/*
  # Create Protocols Table
  
  Creates the protocols table for managing test protocols and normative data.
  
  1. Table Structure:
    - protocols: Test protocol definitions including criteria and normative data
  
  2. Security:
    - RLS enabled
    - Read access for all authenticated users
    - Management access for coaches
*/

-- Create protocols table
CREATE TABLE IF NOT EXISTS protocols (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  unit text NOT NULL,
  criteria text CHECK (criteria IN ('lower', 'higher')),
  categories text[] NOT NULL,
  normative_data jsonb NOT NULL,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE protocols ENABLE ROW LEVEL SECURITY;

-- Create policies if they don't exist
DO $$ BEGIN
  -- Read policy
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'protocols' 
    AND policyname = 'Anyone can read protocols'
  ) THEN
    CREATE POLICY "Anyone can read protocols" ON protocols
      FOR SELECT TO authenticated
      USING (true);
  END IF;

  -- Management policy
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'protocols' 
    AND policyname = 'Coaches can manage protocols'
  ) THEN
    CREATE POLICY "Coaches can manage protocols" ON protocols
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'lead_coach', 'fitness_trainer')
      ));
  END IF;
END $$;