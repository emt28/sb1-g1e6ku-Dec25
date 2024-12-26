/*
  # Create Users Extension Table and Policies
  
  1. Creates the users_extension table with proper constraints
  2. Sets up RLS policies for access control
  3. Creates trigger for updated_at timestamp
  4. Grants necessary permissions
*/

-- Drop existing table and dependencies if they exist
DROP TABLE IF EXISTS public.users_extension CASCADE;

-- Create users_extension table
CREATE TABLE public.users_extension (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer', 'parent', 'player')),
  is_active boolean DEFAULT true,
  preferences jsonb DEFAULT '{"emailNotifications": true, "reportUpdates": true, "attendanceAlerts": true}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.users_extension ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.users_extension
  FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.users_extension
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Only admins can insert profiles"
  ON public.users_extension
  FOR INSERT
  WITH CHECK (
    auth.jwt() ->> 'role' = 'admin' OR 
    auth.uid() = id
  );

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_extension_updated_at
  BEFORE UPDATE ON public.users_extension
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.users_extension TO authenticated;
GRANT SELECT ON public.users_extension TO anon;