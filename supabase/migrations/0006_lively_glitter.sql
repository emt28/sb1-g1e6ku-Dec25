/*
  # Add RLS policies for users table
  
  1. Security Changes
    - Add RLS policies for the users table to allow:
      - Public read access to user profiles
      - Users to update their own profiles
      - Admin users to have full access
      
  2. Notes
    - These policies are essential for basic auth functionality
    - Enables proper access control while maintaining security
*/

-- Create policies for the users table
CREATE POLICY "Users are viewable by everyone" 
ON public.users
FOR SELECT 
USING (true);

CREATE POLICY "Users can update own record" 
ON public.users
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Only admins can insert/delete"
ON public.users
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users_extension
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.users TO anon;
GRANT ALL ON public.users TO authenticated;