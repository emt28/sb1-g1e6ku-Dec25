/*
  # Users Extension Table
  
  Creates a table for storing additional user information and management.
  
  1. Table Structure:
    - id: Links to auth.users
    - full_name: User's full name
    - role: User role (admin, coach, etc)
    - is_active: Account status
    - preferences: JSON storage for user preferences
    - timestamps: created_at, updated_at
  
  2. Security:
    - RLS enabled
    - Users can read their own data
    - Admins can manage all users
  
  3. Automation:
    - Trigger to create extension record on user creation
*/

-- Create users extension table if not exists
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'users_extension'
  ) THEN
    CREATE TABLE users_extension (
      id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
      full_name text,
      role text CHECK (role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer', 'parent')),
      is_active boolean DEFAULT true,
      preferences jsonb DEFAULT '{}'::jsonb,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );

    -- Enable RLS
    ALTER TABLE users_extension ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Create policies if they don't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'users_extension' 
    AND policyname = 'Users can read own data'
  ) THEN
    CREATE POLICY "Users can read own data" ON users_extension
      FOR SELECT TO authenticated
      USING (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'users_extension' 
    AND policyname = 'Admins can manage all users'
  ) THEN
    CREATE POLICY "Admins can manage all users" ON users_extension
      FOR ALL TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension WHERE id = auth.uid() AND role = 'admin'
      ));
  END IF;
END $$;

-- Create or replace user trigger function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO users_extension (id, full_name, role)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'role')
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();