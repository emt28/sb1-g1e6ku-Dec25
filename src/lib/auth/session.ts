import { supabase } from '../supabase-client';
import { getAuthErrorMessage } from './auth-errors';

export async function signOut(): Promise<void> {
  const { error } = await supabase.auth.signOut();
  if (error) {
    throw new Error(getAuthErrorMessage(error));
  }
}

export async function getCurrentSession() {
  const { data: { session }, error } = await supabase.auth.getSession();
  if (error) {
    throw new Error(getAuthErrorMessage(error));
  }
  return session;
}