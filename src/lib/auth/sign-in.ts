import { supabase } from '../supabase-client';
import { getAuthErrorMessage } from './auth-errors';
import type { User } from '@/types/auth';

export async function signIn(email: string, password: string): Promise<User> {
  try {
    // Clear any existing session
    await supabase.auth.signOut();

    // Attempt to sign in
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      console.error('Auth error:', error);
      throw error;
    }

    if (!data.user) {
      throw new Error('Authentication failed');
    }

    // Get user profile data
    const { data: profile, error: profileError } = await supabase
      .from('users_extension')
      .select('*')
      .eq('id', data.user.id)
      .single();

    if (profileError) {
      console.error('Profile error:', profileError);
      throw new Error('Failed to load user profile');
    }

    if (!profile.is_active) {
      throw new Error('This account has been deactivated');
    }

    return {
      ...data.user,
      ...profile,
    };
  } catch (error) {
    console.error('Sign in error:', error);
    throw new Error(getAuthErrorMessage(error));
  }
}