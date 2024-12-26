/*
  # Admin User Creation Migration
  
  1. Creates admin user using Supabase admin API
  2. Ensures proper role and permissions
  3. Sets up initial admin account with correct user extension
*/

-- Create admin user using Supabase admin API
BEGIN;

-- First check if admin user already exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'eddiemiron@gmail.com'
  ) THEN
    -- Create the admin user using Supabase's admin API
    WITH new_user AS (
      INSERT INTO auth.users (
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        aud,
        role,
        created_at,
        updated_at,
        is_super_admin
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        'eddiemiron@gmail.com',
        crypt('PapucelU28', gen_salt('bf')),
        now(),
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{"name": "6.fitness Admin", "role": "admin"}'::jsonb,
        'authenticated',
        'authenticated',
        now(),
        now(),
        true
      ) RETURNING id, email, raw_user_meta_data
    )
    -- Create corresponding users_extension record
    INSERT INTO public.users_extension (
      id,
      email,
      name,
      role,
      is_active
    )
    SELECT 
      id,
      email,
      raw_user_meta_data->>'name',
      raw_user_meta_data->>'role',
      true
    FROM new_user;
  END IF;
END $$;

COMMIT;