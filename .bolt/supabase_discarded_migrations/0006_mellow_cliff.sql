-- Drop and recreate users_extension table with proper constraints
DROP TABLE IF EXISTS public.users_extension CASCADE;

CREATE TABLE public.users_extension (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
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
CREATE POLICY "Admins have full access" ON public.users_extension
  FOR ALL 
  TO authenticated
  USING (
    role = 'admin'
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

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users_extension (
    id,
    email,
    name,
    role
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'player')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user handling
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create initial admin user
BEGIN;
  -- Use Supabase's auth.users() function to create admin
  SELECT auth.create_user(
    jsonb_build_object(
      'email', 'admin@6fitness.com',
      'password', 'Admin123!',
      'email_confirm', true,
      'user_metadata', jsonb_build_object(
        'name', '6.fitness Admin',
        'role', 'admin'
      )
    )
  );
COMMIT;