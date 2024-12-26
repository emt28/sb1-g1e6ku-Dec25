import { supabase } from '../supabase-client';
import { getAuthErrorMessage } from './auth-errors';
import type { User, UserRole } from '@/types/auth';

export async function signUp(
  email: string,
  password: string,
  role: UserRole,
  name: string
): Promise<User> {
  try {
    // First create the auth user
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          name,
          role,
        },
      },
    });

    if (authError) throw authError;
    if (!authData.user) throw new Error('Failed to create user account');

    // Then create the profile in a separate transaction
    const { data: profile, error: profileError } = await supabase
      .from('users_extension')
      .insert({
        id: authData.user.id,
        email,
        name,
        role,
        is_active: true,
      })
      .select()
      .single();

    if (profileError) {
      // If profile creation fails, we should clean up the auth user
      await supabase.auth.admin.deleteUser(authData.user.id);
      throw new Error('Failed to create user profile');
    }

    return {
      ...authData.user,
      ...profile,
    };
  } catch (error) {
    console.error('Sign up error:', error);
    throw new Error(getAuthErrorMessage(error));
  }
}