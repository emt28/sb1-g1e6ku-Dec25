/*
  # Audit Logs Table
  
  Creates a table for tracking system activity and changes.
  
  1. Table Structure:
    - id: UUID primary key
    - action: Type of action performed
    - user_id: Reference to user who performed action
    - details: Description of the action
    - timestamp: When action occurred
  
  2. Security:
    - RLS enabled
    - Only admins can read audit logs
*/

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
  END IF;
END $$;

-- Create policy if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'audit_logs' 
    AND policyname = 'Only admins can read audit logs'
  ) THEN
    CREATE POLICY "Only admins can read audit logs" ON audit_logs
      FOR SELECT TO authenticated
      USING (EXISTS (
        SELECT 1 FROM users_extension 
        WHERE id = auth.uid() AND role = 'admin'
      ));
  END IF;
END $$;