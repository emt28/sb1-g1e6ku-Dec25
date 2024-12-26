-- Create users_extension table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.users_extension (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'lead_coach', 'academy_coach', 'fitness_trainer', 'parent', 'player')),
  is_active boolean DEFAULT true,
  preferences jsonb DEFAULT '{"emailNotifications": true, "reportUpdates": true, "attendanceAlerts": true}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS if not already enabled
ALTER TABLE public.users_extension ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins have full access" ON public.users_extension;
DROP POLICY IF EXISTS "Users can read own data" ON public.users_extension;
DROP POLICY IF EXISTS "Users can update own data" ON public.users_extension;

-- Recreate policies
CREATE POLICY "Admins have full access" ON public.users_extension
  FOR ALL 
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users_extension 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can read own data" ON public.users_extension
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can update own data" ON public.users_extension
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Create or replace trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS update_users_extension_updated_at ON users_extension;
CREATE TRIGGER update_users_extension_updated_at
  BEFORE UPDATE ON users_extension
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();