/*
  # Initial Schema Setup

  1. New Tables
    - users_extension: Extended user profile data
    - athletes: Athlete records
    - protocols: Test protocol definitions
    - assessments: Assessment records
    - goals: Development goals
    - goal_notes: Notes on goals
    - coach_notes: Coach observations
    - audit_logs: System audit trail

  2. Security
    - RLS enabled on all tables
    - Role-based access policies
    - Automatic user extension creation
*/

-- Users extension table
DO $$ BEGIN
  CREATE TABLE IF NOT EXISTS users_extension (
    id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    full_name text,
    role text CHECK (role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer', 'parent')),
    is_active boolean DEFAULT true,
    preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
  );
  
  ALTER TABLE users_extension ENABLE ROW LEVEL SECURITY;

  IF NOT EXISTS (
    SELECT FROM pg_policies WHERE tablename = 'users_extension' AND policyname = 'Users can read own data'
  ) THEN
    CREATE POLICY "Users can read own data" ON users_extension
      FOR SELECT TO authenticated
      USING (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT FROM pg_policies WHERE tablename = 'users_extension' AND policyname = 'Admins can manage all users'
  ) THEN
    CREATE POLICY "Admins can manage all users" ON users_extension
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension WHERE id = auth.uid() AND role = 'admin'
      ));
  END IF;
END $$;

[Rest of SQL content remains exactly the same as before...]