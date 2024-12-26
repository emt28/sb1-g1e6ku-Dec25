import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

// Get environment variables
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Validate environment variables
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Missing required environment variables: VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY must be set'
  );
}

// Create Supabase client with proper configuration
export const supabase = createClient<Database>(
  supabaseUrl,
  supabaseAnonKey,
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
      storage: localStorage,
      flowType: 'pkce' // Enable PKCE flow for better security
    }
  }
);

// Helper to get current user with profile data
export const getCurrentUser = async () => {
  try {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) throw error;
    if (!user) return null;

    const { data: profile, error: profileError } = await supabase
      .from('users_extension')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileError) throw profileError;

    return {
      ...user,
      ...profile,
    };
  } catch (error) {
    console.error('Error getting current user:', error);
    return null;
  }
};