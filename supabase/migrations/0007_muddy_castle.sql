/*
  # Create Goals and Notes Tables
  
  Creates tables for tracking athlete development goals and related notes.
  
  1. Tables:
    - goals: Development goals for athletes
    - goal_notes: Notes and updates for goals
  
  2. Security:
    - RLS enabled for both tables
    - Management access for coaches and trainers
*/

-- Create goals table
CREATE TABLE IF NOT EXISTS goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id uuid REFERENCES athletes NOT NULL,
  title text NOT NULL,
  description text,
  category text CHECK (category IN ('physical', 'tactical', 'technical', 'mental', 'other')),
  target_metric jsonb,
  deadline date,
  progress numeric DEFAULT 0,
  status text DEFAULT 'onTrack' CHECK (status IN ('onTrack', 'atRisk', 'offTrack', 'completed')),
  protocol_id uuid REFERENCES protocols,
  assigned_to uuid REFERENCES auth.users,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS for goals
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

-- Create goals policy if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'goals' 
    AND policyname = 'Coaches can manage goals'
  ) THEN
    CREATE POLICY "Coaches can manage goals" ON goals
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer')
      ));
  END IF;
END $$;

-- Create goal notes table
CREATE TABLE IF NOT EXISTS goal_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid REFERENCES goals NOT NULL,
  text text NOT NULL,
  created_by uuid REFERENCES auth.users NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS for goal notes
ALTER TABLE goal_notes ENABLE ROW LEVEL SECURITY;

-- Create goal notes policy if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'goal_notes' 
    AND policyname = 'Coaches can manage goal notes'
  ) THEN
    CREATE POLICY "Coaches can manage goal notes" ON goal_notes
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer')
      ));
  END IF;
END $$;