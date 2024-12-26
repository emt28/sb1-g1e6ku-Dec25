export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users_extension: {
        Row: {
          id: string
          email: string
          name: string
          role: 'admin' | 'lead_coach' | 'academy_coach' | 'fitness_trainer' | 'parent' | 'player'
          is_active: boolean
          preferences: Json
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          email: string
          name: string
          role: 'admin' | 'lead_coach' | 'academy_coach' | 'fitness_trainer' | 'parent' | 'player'
          is_active?: boolean
          preferences?: Json
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          name?: string
          role?: 'admin' | 'lead_coach' | 'academy_coach' | 'fitness_trainer' | 'parent' | 'player'
          is_active?: boolean
          preferences?: Json
          created_at?: string
          updated_at?: string
        }
      }
      // ... other tables
    }
  }
}