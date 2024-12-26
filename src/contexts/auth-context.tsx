import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase-client';
import { signIn, signUp, signOut } from '@/lib/auth';
import type { User, AuthContextType } from '@/types/auth';

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const checkSession = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session?.user) {
          const { data: profile } = await supabase
            .from('users_extension')
            .select('*')
            .eq('id', session.user.id)
            .single();
            
          setUser(profile ? { ...session.user, ...profile } : null);
        }
      } catch (err) {
        console.error('Error loading user:', err);
      } finally {
        setIsLoading(false);
      }
    };

    checkSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        const { data: profile } = await supabase
          .from('users_extension')
          .select('*')
          .eq('id', session.user.id)
          .single();
          
        setUser(profile ? { ...session.user, ...profile } : null);
      } else {
        setUser(null);
      }
      setIsLoading(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const handleSignIn = async (email: string, password: string) => {
    try {
      setError(null);
      setIsLoading(true);
      const user = await signIn(email, password);
      setUser(user);
      return user;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to sign in');
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignUp = async (email: string, password: string, role: string, name: string) => {
    try {
      setError(null);
      setIsLoading(true);
      const user = await signUp(email, password, role as any, name);
      setUser(user);
      return user;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create account');
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      setError(null);
      await signOut();
      setUser(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to sign out');
      console.error('Sign out error:', err);
    }
  };

  const value = {
    user,
    isLoading,
    error,
    isAuthenticated: !!user,
    signIn: handleSignIn,
    signUp: handleSignUp,
    signOut: handleSignOut,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}