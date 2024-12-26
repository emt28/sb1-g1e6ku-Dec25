/*
  # Coach Notes and Audit Logs Tables
  
  1. Coach Notes Table:
    - Stores coach feedback and notes about athletes
    - Supports different note types and visibility levels
    - RLS enabled with coach-only access
    
  2. Audit Logs Table:
    - Tracks system activity and changes
    - Admin-only access through RLS
    - Captures user actions with timestamps
*/

-- Create coach notes table if not exists
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'coach_notes'
  ) THEN
    CREATE TABLE coach_notes (
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

    -- Create coach notes policy
    CREATE POLICY "Coaches can manage notes" ON coach_notes
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer')
      ));
  END IF;
END $$;

-- Create audit logs table if not exists
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'audit_logs'
  ) THEN
    CREATE TABLE audit_logs (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      action text NOT NULL,
      user_id uuid REFERENCES auth.users NOT NULL,
      details text NOT NULL,
      timestamp timestamptz DEFAULT now()
    );

    -- Enable RLS
    ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

    -- Create audit logs policy
    CREATE POLICY "Only admins can read audit logs" ON audit_logs
      FOR SELECT TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() AND role = 'admin'
      ));
  END IF;
END $$;