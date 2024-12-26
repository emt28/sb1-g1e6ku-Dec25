import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';
import type { User, UserRole } from '@/types/auth';

// Mock admin functions for development when service role key is not available
const mockAdminFunctions = {
  createUserWithExtension: async (email: string, password: string, role: UserRole, name: string) => {
    console.warn('Using mock admin functions - service role key not available');
    // Return mock user data
    return {
      id: '1',
      email,
      role,
      name,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    } as User;
  }
};

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseServiceKey = import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

// Initialize admin client only if service role key is available
export const supabaseAdmin = supabaseUrl && supabaseServiceKey ? 
  createClient<Database>(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: false
    }
  }) : null;

export async function createUserWithExtension(
  email: string, 
  password: string,
  role: UserRole,
  name: string
): Promise<User> {
  // If admin client is not available, use mock functions
  if (!supabaseAdmin) {
    return mockAdminFunctions.createUserWithExtension(email, password, role, name);
  }

  // Create user with auth API
  const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      name,
      role
    }
  });

  if (authError) {
    console.error('Error creating user:', authError);
    throw authError;
  }

  if (!authData.user) {
    throw new Error('No user returned from auth API');
  }

  // Create user extension record
  const { data: profile, error: profileError } = await supabaseAdmin
    .from('users_extension')
    .insert({
      id: authData.user.id,
      email: authData.user.email!,
      name,
      role,
      is_active: true
    })
    .select()
    .single();

  if (profileError) {
    console.error('Error creating user extension:', profileError);
    // Clean up auth user if extension fails
    await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
    throw profileError;
  }

  return {
    ...authData.user,
    ...profile
  };
}