/*
  # Create Initial Admin User
  
  1. Creates admin user using Supabase's admin API
  2. Ensures proper role and metadata
  3. Handles user extension record creation via trigger
*/

-- Create admin user using Supabase's admin API
SELECT supabase_admin.create_user(
  '{
    "email": "admin@6fitness.com",
    "password": "Admin123!",
    "email_confirm": true,
    "user_metadata": {
      "name": "6.fitness Admin",
      "role": "admin"
    }
  }'::jsonb
) WHERE NOT EXISTS (
  SELECT 1 FROM auth.users 
  WHERE email = 'admin@6fitness.com'
);