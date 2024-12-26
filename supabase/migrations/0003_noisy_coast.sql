/*
  # Create users extension table and policies

  1. New Tables
    - `users_extension` - Extends auth.users with additional user data
  
  2. Security
    - RLS enabled with granular access policies
    - Automatic triggers for timestamps and user creation
*/

-- Create users_extension table if not exists
CREATE TABLE IF NOT EXISTS users_extension (
  id uuid PRIMARY KEY REFERENCES auth.users,
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer', 'parent', 'player')),
  is_active boolean DEFAULT true,
  preferences jsonb DEFAULT '{"emailNotifications": true, "reportUpdates": true, "attendanceAlerts": true}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users_extension ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins have full access" ON users_extension;
DROP POLICY IF EXISTS "Users can read own data" ON users_extension;
DROP POLICY IF EXISTS "Users can update own data" ON users_extension;

-- Create admin access policy
CREATE POLICY "Admins have full access"
ON users_extension
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users_extension 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Create user read policy
CREATE POLICY "Users can read own data"
ON users_extension
FOR SELECT
USING (id = auth.uid());

-- Create user update policy
CREATE POLICY "Users can update own data"
ON users_extension
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Drop existing functions and triggers if they exist
DROP TRIGGER IF EXISTS update_users_extension_updated_at ON users_extension;
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create updated_at trigger function
CREATE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create updated_at trigger
CREATE TRIGGER update_users_extension_updated_at
  BEFORE UPDATE ON users_extension
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create new user handler function
CREATE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users_extension (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'player')
  );
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create new user trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();